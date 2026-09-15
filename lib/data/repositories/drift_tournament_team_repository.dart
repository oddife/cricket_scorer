import 'package:drift/drift.dart';

import '../../domain/teams/models/team.dart' as domain;
import '../database/app_database.dart';
import 'tournament_team_repository.dart';

class DriftTournamentTeamRepository implements TournamentTeamRepository {
  DriftTournamentTeamRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Team>> getTeams(int tournamentId) async {
    final query = _database.select(_database.teams).join([
      innerJoin(
        _database.tournamentTeams,
        _database.tournamentTeams.teamId.equalsExp(_database.teams.id),
      ),
    ])
      ..where(_database.tournamentTeams.tournamentId.equals(tournamentId))
      ..where(_database.teams.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(_database.teams.name)]);

    final rows = await query.get();
    return rows.map((row) {
      final teamRow = row.readTable(_database.teams);
      return domain.Team(
        id: teamRow.id,
        name: teamRow.name,
        shortName: teamRow.shortName,
        logoPath: teamRow.logoPath,
        isActive: teamRow.isActive,
      );
    }).toList(growable: false);
  }

  @override
  Future<void> addTeam({required int tournamentId, required int teamId}) async {
    await _database.into(_database.tournamentTeams).insertOnConflictUpdate(
          TournamentTeamsCompanion.insert(
            tournamentId: tournamentId,
            teamId: teamId,
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> removeTeam({required int tournamentId, required int teamId}) async {
    await (_database.delete(_database.tournamentTeams)
          ..where((table) => table.tournamentId.equals(tournamentId))
          ..where((table) => table.teamId.equals(teamId)))
        .go();
  }
}
