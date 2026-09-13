import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/matches/enums/match_team_slot.dart';
import '../../../domain/matches/enums/toss_decision.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/matches/models/match_player.dart';
import '../../../domain/matches/models/match_team.dart';

final matchProvider = AsyncNotifierProvider<MatchNotifier, List<Match>>(
  MatchNotifier.new,
);

final matchByIdProvider = FutureProvider.family<Match?, int>((ref, matchId) {
  return ref.watch(matchRepositoryProvider).getById(matchId);
});

final matchTeamsProvider = FutureProvider.family<List<MatchTeam>, int>(
  (ref, matchId) {
    return ref.watch(matchRepositoryProvider).getTeams(matchId);
  },
);

final matchPlayersProvider = FutureProvider.family<List<MatchPlayer>, int>(
  (ref, matchId) {
    return ref.watch(matchRepositoryProvider).getPlayers(matchId);
  },
);

class MatchNotifier extends AsyncNotifier<List<Match>> {
  @override
  Future<List<Match>> build() {
    return ref.watch(matchRepositoryProvider).getAll();
  }

  Future<Match> create(Match match) async {
    final created = await ref.read(matchRepositoryProvider).create(match);
    ref.invalidateSelf();
    await future;
    return created;
  }

  Future<void> update(Match match) async {
    await ref.read(matchRepositoryProvider).update(match);
    ref.invalidateSelf();
    await future;
    ref.invalidate(matchByIdProvider(match.id));
  }

  Future<void> delete(int matchId) async {
    await ref.read(matchRepositoryProvider).delete(matchId);
    ref.invalidateSelf();
    await future;
    ref.invalidate(matchByIdProvider(matchId));
    ref.invalidate(matchTeamsProvider(matchId));
    ref.invalidate(matchPlayersProvider(matchId));
  }

  Future<void> setTeam({
    required int matchId,
    required int teamId,
    required MatchTeamSlot slot,
  }) async {
    await ref.read(matchRepositoryProvider).setTeam(
          matchId: matchId,
          teamId: teamId,
          slot: slot,
        );
    ref.invalidate(matchTeamsProvider(matchId));
  }

  Future<void> removeTeam(int matchId, MatchTeamSlot slot) async {
    await ref.read(matchRepositoryProvider).removeTeam(matchId, slot);
    ref.invalidate(matchTeamsProvider(matchId));
  }

  Future<void> addPlayer({
    required int matchId,
    required int teamId,
    required int playerId,
  }) async {
    await ref.read(matchRepositoryProvider).addPlayer(
          matchId: matchId,
          teamId: teamId,
          playerId: playerId,
        );
    ref.invalidate(matchPlayersProvider(matchId));
  }

  Future<void> removePlayer(int matchId, int playerId) async {
    await ref.read(matchRepositoryProvider).removePlayer(matchId, playerId);
    ref.invalidate(matchPlayersProvider(matchId));
  }

  Future<void> setPlayingXi({
    required int matchId,
    required int teamId,
    required List<int> playerIds,
  }) async {
    await ref.read(matchRepositoryProvider).setPlayingXi(
          matchId: matchId,
          teamId: teamId,
          playerIds: playerIds,
        );
    ref.invalidate(matchPlayersProvider(matchId));
  }

  Future<void> setToss({
    required int matchId,
    required int tossWinnerTeamId,
    required TossDecision decision,
  }) async {
    await ref.read(matchRepositoryProvider).setToss(
          matchId: matchId,
          tossWinnerTeamId: tossWinnerTeamId,
          decision: decision,
        );
    ref.invalidate(matchByIdProvider(matchId));
    ref.invalidateSelf();
    await future;
  }
}
