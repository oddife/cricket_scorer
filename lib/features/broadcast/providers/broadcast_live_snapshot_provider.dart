import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../application/scoring/apply_scoring_action_service.dart';
import '../../../application/sync/sync_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../data/repositories/innings_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../domain/innings/enums/innings_status.dart';
import '../../../domain/innings/models/innings.dart';
import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/players/models/player.dart';
import '../../matches/providers/live_scoring_provider.dart';
import '../../players/providers/player_provider.dart';
import '../application/broadcast_snapshot_builder.dart';
import '../models/broadcast_snapshot.dart';

/// Explicit selection lets the Broadcast Manager pin a particular innings.
/// With no selection, the most recent live match/innings is selected.
final broadcastSelectedInningsIdProvider = StateProvider<int?>((ref) => null);

/// Read-only view of the live local match for browser outputs and the manager.
/// It reuses the existing scoring notifier and repositories; it never writes
/// scores or reimplements scoring rules.
final broadcastLiveSnapshotProvider =
    FutureProvider<BroadcastSnapshot>((ref) async {
  // Rebuild when sync imports match changes or catalog downloads player/team
  // names. Watching the whole scoring AsyncValue also refreshes after score,
  // wicket, undo, and local recovery operations.
  ref.watch(syncDataRefreshProvider);
  ref.watch(catalogSyncRefreshProvider);

  final selectedInningsId = ref.watch(broadcastSelectedInningsIdProvider);
  final inningsRepository = ref.watch(inningsRepositoryProvider);
  final matchRepository = ref.watch(matchRepositoryProvider);
  final ballEventRepository = ref.watch(ballEventRepositoryProvider);

  final Innings? innings;
  if (selectedInningsId != null) {
    innings = await inningsRepository.getById(selectedInningsId);
  } else {
    innings = await _findCurrentLiveInnings(
      matchRepository: matchRepository,
      inningsRepository: inningsRepository,
    );
  }

  if (innings == null) return BroadcastSnapshot.empty();

  final match = await matchRepository.getById(innings.matchId);
  if (match == null) return BroadcastSnapshot.empty();

  final liveScoring = liveScoringProvider(innings.id);
  ref.watch(liveScoring);
  final scoringState = await ref.watch(liveScoring.future);

  final matchTeams = await matchRepository.getTeams(match.id);
  final teams =
      await ref.watch(teamRepositoryProvider).getAllIncludingInactive();
  final List<Player> players = await ref.watch(playerProvider.future);
  final events = await ballEventRepository.getForInnings(innings.id);
  final target = await ref
      .watch(applyScoringActionServiceProvider)
      .targetForInnings(innings);

  return BroadcastSnapshotBuilder.build(
    match: match,
    innings: scoringState.innings,
    score: scoringState.score,
    strikerId: scoringState.liveStrikerId,
    nonStrikerId: scoringState.liveNonStrikerId,
    selectedBowlerId: scoringState.selectedBowlerId,
    matchTeams: matchTeams,
    teams: teams,
    matchPlayers: await matchRepository.getPlayers(match.id),
    players: players,
    events: events,
    target: target,
  );
});

Future<Innings?> _findCurrentLiveInnings({
  required MatchRepository matchRepository,
  required InningsRepository inningsRepository,
}) async {
  final matches = (await matchRepository.getAll())
      .where((match) => match.status == MatchStatus.live)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  for (final Match match in matches) {
    final innings = (await inningsRepository.getForMatch(match.id)).toList()
      ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    if (innings.isEmpty) continue;

    final liveInnings =
        innings.where((item) => item.status == InningsStatus.live).toList();
    if (liveInnings.isNotEmpty) {
      liveInnings.sort((a, b) => b.inningsNumber.compareTo(a.inningsNumber));
      return liveInnings.first;
    }

    // Some previously saved live matches may have a live match status but
    // legacy innings status. Prefer the latest innings for display.
    return innings.last;
  }
  return null;
}
