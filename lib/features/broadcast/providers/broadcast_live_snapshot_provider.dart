import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../application/sync/sync_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/innings/enums/innings_status.dart';
import '../../../domain/innings/models/innings.dart';
import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/players/models/player.dart';
import '../../matches/providers/innings_provider.dart';
import '../../matches/providers/live_scoring_provider.dart';
import '../../matches/providers/match_provider.dart';
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

  // Subscribe to local match creation/update and to innings initialization,
  // including when the broadcast window opens before a match starts.
  ref.watch(matchProvider);
  final matches = await ref.watch(matchProvider.future);

  final Innings? innings;
  if (selectedInningsId != null) {
    innings = await inningsRepository.getById(selectedInningsId);
  } else {
    final liveMatches = matches
        .where((match) => match.status == MatchStatus.live)
        .toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });

    Innings? currentInnings;
    for (final candidateMatch in liveMatches) {
      final inningsProvider = inningsByMatchProvider(candidateMatch.id);
      ref.watch(inningsProvider);
      final matchInnings = await ref.watch(inningsProvider.future);
      if (matchInnings.isEmpty) continue;

      final activeInnings = matchInnings
          .where((item) => item.status == InningsStatus.live)
          .toList()
        ..sort((a, b) => b.inningsNumber.compareTo(a.inningsNumber));
      if (activeInnings.isNotEmpty) {
        currentInnings = activeInnings.first;
      } else {
        // Legacy live matches may not mark the innings status consistently.
        final ordered = matchInnings.toList()
          ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
        currentInnings = ordered.last;
      }
      break;
    }
    innings = currentInnings;
  }

  if (innings == null) return BroadcastSnapshot.empty();

  final inningListProvider = inningsByMatchProvider(innings.matchId);
  ref.watch(inningListProvider);
  await ref.watch(inningListProvider.future);

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
    automaticEventsEligible: match.status == MatchStatus.live &&
        (selectedInningsId == null || innings.status == InningsStatus.live),
  );
});
