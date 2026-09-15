import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/teams/models/team.dart';

final tournamentTeamsProvider = FutureProvider.family<List<Team>, int>(
  (ref, tournamentId) =>
      ref.watch(tournamentTeamRepositoryProvider).getTeams(tournamentId),
);

final tournamentTeamNotifierProvider =
    NotifierProvider.family<TournamentTeamNotifier, void, int>(
  TournamentTeamNotifier.new,
);

class TournamentTeamNotifier extends FamilyNotifier<void, int> {
  @override
  void build(int tournamentId) {}

  Future<void> addTeam(int teamId) async {
    await ref.read(tournamentTeamRepositoryProvider).addTeam(
          tournamentId: arg,
          teamId: teamId,
        );
    ref.invalidate(tournamentTeamsProvider(arg));
  }

  Future<void> removeTeam(int teamId) async {
    await ref.read(tournamentTeamRepositoryProvider).removeTeam(
          tournamentId: arg,
          teamId: teamId,
        );
    ref.invalidate(tournamentTeamsProvider(arg));
  }
}
