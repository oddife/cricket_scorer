import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/teams/models/team.dart';

final tournamentTeamsProvider =
    FutureProvider.family<List<Team>, int>((ref, tournamentId) {
  return ref.watch(tournamentTeamRepositoryProvider).getTeams(tournamentId);
});

class TournamentTeamNotifier extends FamilyAsyncNotifier<List<Team>, int> {
  @override
  Future<List<Team>> build(int tournamentId) {
    return ref.watch(tournamentTeamRepositoryProvider).getTeams(tournamentId);
  }

  Future<void> addTeam(int teamId) async {
    await ref.read(tournamentTeamRepositoryProvider).addTeam(
          tournamentId: arg,
          teamId: teamId,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeTeam(int teamId) async {
    await ref.read(tournamentTeamRepositoryProvider).removeTeam(
          tournamentId: arg,
          teamId: teamId,
        );
    ref.invalidateSelf();
    await future;
  }
}

final tournamentTeamNotifierProvider =
    AsyncNotifierProvider.family<TournamentTeamNotifier, List<Team>, int>(
  TournamentTeamNotifier.new,
);
