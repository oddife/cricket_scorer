import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/teams/models/team.dart';

final tournamentTeamsProvider = FutureProvider.family<List<Team>, int>(
  (ref, tournamentId) =>
      ref.watch(tournamentTeamRepositoryProvider).getTeams(tournamentId),
);

final tournamentTeamControllerProvider =
    Provider.family<TournamentTeamController, int>(
  (ref, tournamentId) => TournamentTeamController(ref, tournamentId),
);

class TournamentTeamController {
  TournamentTeamController(this._ref, this.tournamentId);

  final Ref _ref;
  final int tournamentId;

  Future<void> addTeam(int teamId) async {
    await _ref.read(tournamentTeamRepositoryProvider).addTeam(
          tournamentId: tournamentId,
          teamId: teamId,
        );
    _ref.invalidate(tournamentTeamsProvider(tournamentId));
  }

  Future<void> removeTeam(int teamId) async {
    await _ref.read(tournamentTeamRepositoryProvider).removeTeam(
          tournamentId: tournamentId,
          teamId: teamId,
        );
    _ref.invalidate(tournamentTeamsProvider(tournamentId));
  }
}
