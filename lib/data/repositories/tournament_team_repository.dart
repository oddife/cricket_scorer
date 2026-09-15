import '../../domain/teams/models/team.dart';

abstract interface class TournamentTeamRepository {
  Future<List<Team>> getTeams(int tournamentId);

  Future<void> addTeam({required int tournamentId, required int teamId});

  Future<void> removeTeam({required int tournamentId, required int teamId});
}
