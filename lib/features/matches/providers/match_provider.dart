import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/sync/sync_provider.dart';
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
  ref.watch(syncDataRefreshProvider);
  return ref.watch(matchRepositoryProvider).getById(matchId);
});

final matchTeamsProvider = FutureProvider.family<List<MatchTeam>, int>(
  (ref, matchId) {
    ref.watch(syncDataRefreshProvider);
    return ref.watch(matchRepositoryProvider).getTeams(matchId);
  },
);

final matchPlayersProvider = FutureProvider.family<List<MatchPlayer>, int>(
  (ref, matchId) {
    ref.watch(syncDataRefreshProvider);
    return ref.watch(matchRepositoryProvider).getPlayers(matchId);
  },
);

class MatchNotifier extends AsyncNotifier<List<Match>> {
  @override
  Future<List<Match>> build() {
    // Re-query match metadata when another device's sync import changes it.
    ref.watch(syncDataRefreshProvider);
    return ref.watch(matchRepositoryProvider).getAll();
  }

  Future<Match> createMatch(Match match) async {
    final created = await ref.read(matchRepositoryProvider).create(match);
    ref.invalidateSelf();
    await future;
    return created;
  }

  Future<void> updateMatch(Match match) async {
    await ref.read(matchRepositoryProvider).update(match);
    ref.invalidateSelf();
    await future;
    ref.invalidate(matchByIdProvider(match.id));
  }

  Future<void> deleteMatch(int matchId) async {
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

  /// Adds a late-arriving player to a match and makes them available immediately.
  /// Existing availability for the same team is preserved.
  Future<void> addAvailablePlayerToMatch({
    required int matchId,
    required int teamId,
    required int playerId,
  }) async {
    final repository = ref.read(matchRepositoryProvider);
    final match = await repository.getById(matchId);
    if (match == null) throw StateError('Match not found.');

    final teams = await repository.getTeams(matchId);
    if (!teams.any((team) => team.teamId == teamId)) {
      throw ArgumentError('Selected team does not belong to this match.');
    }

    final before = await repository.getPlayers(matchId);
    if (before.any((player) => player.playerId == playerId)) {
      throw StateError('Player is already part of this match.');
    }
    final teamCount = before.where((player) => player.teamId == teamId).length;
    if (teamCount >= match.playersPerTeam) {
      throw StateError(
        'This team has reached the configured limit of ${match.playersPerTeam} players.',
      );
    }

    await repository.addPlayer(
      matchId: matchId,
      teamId: teamId,
      playerId: playerId,
    );

    try {
      final after = await repository.getPlayers(matchId);
      final availableIds = after
          .where((player) => player.teamId == teamId && player.isPlaying)
          .map((player) => player.playerId)
          .toList();
      if (!availableIds.contains(playerId)) availableIds.add(playerId);

      await repository.setAvailablePlayers(
        matchId: matchId,
        teamId: teamId,
        playerIds: availableIds,
      );
    } catch (_) {
      try {
        await repository.removePlayer(matchId, playerId);
      } catch (_) {
        // Preserve the original failure if rollback is unavailable.
      }
      rethrow;
    }

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
