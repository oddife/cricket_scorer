import 'package:drift/drift.dart';
import '../../domain/teams/models/team.dart' as domain;
import '../database/app_database.dart';
import 'catalog_sync_queue_repository.dart';
import 'sync_identity_repository.dart';
import 'tournament_team_repository.dart';

class DriftTournamentTeamRepository implements TournamentTeamRepository {
  DriftTournamentTeamRepository(this._database, [this._queue, this._identity]);
  final AppDatabase _database;
  final CatalogSyncQueueRepository? _queue;
  final SyncIdentityRepository? _identity;

  @override
  Future<List<domain.Team>> getTeams(int tournamentId) async {
    final query = _database.select(_database.teams).join([
      innerJoin(_database.tournamentTeams, _database.tournamentTeams.teamId.equalsExp(_database.teams.id)),
    ])
      ..where(_database.tournamentTeams.tournamentId.equals(tournamentId))
      ..where(_database.teams.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(_database.teams.name)]);
    final rows = await query.get();
    return rows.map((row) {
      final team = row.readTable(_database.teams);
      return domain.Team(id: team.id, name: team.name, shortName: team.shortName, logoPath: team.logoPath, isActive: team.isActive);
    }).toList(growable: false);
  }

  @override
  Future<void> addTeam({required int tournamentId, required int teamId}) async {
    await _database.into(_database.tournamentTeams).insertOnConflictUpdate(
      TournamentTeamsCompanion.insert(tournamentId: tournamentId, teamId: teamId, createdAt: DateTime.now()),
    );
    await _enqueueTournament(tournamentId);
  }

  @override
  Future<void> removeTeam({required int tournamentId, required int teamId}) async {
    await (_database.delete(_database.tournamentTeams)
          ..where((table) => table.tournamentId.equals(tournamentId))
          ..where((table) => table.teamId.equals(teamId)))
        .go();
    await _enqueueTournament(tournamentId);
  }

  Future<void> _enqueueTournament(int tournamentId) async {
    final queue = _queue;
    final identity = _identity;
    if (queue == null || identity == null) return;
    await queue.enqueue(
      syncId: await identity.ensureTournamentSyncId(tournamentId),
      entityType: 'tournament',
      entityId: tournamentId,
    );
  }
}
