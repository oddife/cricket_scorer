import 'package:drift/drift.dart';

import '../../domain/teams/models/team.dart' as domain;
import '../database/app_database.dart';
import 'catalog_sync_queue_repository.dart';
import 'team_repository.dart';

class DriftTeamRepository implements TeamRepository {
  DriftTeamRepository(this._database, [this._catalogSyncQueueRepository]);

  final AppDatabase _database;
  final CatalogSyncQueueRepository? _catalogSyncQueueRepository;

  @override
  Future<List<domain.Team>> getAll() async {
    return _readTeams(activeOnly: true);
  }

  @override
  Future<List<domain.Team>> getAllIncludingInactive() async {
    return _readTeams(activeOnly: false);
  }

  Future<List<domain.Team>> _readTeams({required bool activeOnly}) async {
    final query = _database.select(_database.teams);
    if (activeOnly) {
      query.where((row) => row.isActive.equals(true));
    }
    query.orderBy([(row) => OrderingTerm.asc(row.name)]);
    final rows = await query.get();
    return rows.map<domain.Team>(_toDomain).toList(growable: false);
  }

  @override
  Future<domain.Team> create(domain.Team team) async {
    final now = DateTime.now();
    final id = await _database.into(_database.teams).insert(
          TeamsCompanion.insert(
            name: team.name,
            shortName: team.shortName,
            logoPath: Value(team.logoPath),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final created = domain.Team(
      id: id,
      name: team.name,
      shortName: team.shortName,
      logoPath: team.logoPath,
      isActive: true,
    );
    await _enqueue(created.id);
    return created;
  }

  @override
  Future<void> update(domain.Team team) async {
    await (_database.update(_database.teams)
          ..where((row) => row.id.equals(team.id)))
        .write(
      TeamsCompanion(
        name: Value(team.name),
        shortName: Value(team.shortName),
        logoPath: Value(team.logoPath),
        isActive: Value(team.isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _enqueue(team.id);
  }

  @override
  Future<void> deactivate(int teamId) async {
    await (_database.update(_database.teams)
          ..where((row) => row.id.equals(teamId)))
        .write(
      TeamsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _enqueue(teamId);
  }

  Future<void> _enqueue(int teamId) async {
    final queue = _catalogSyncQueueRepository;
    if (queue == null) return;
    await queue.enqueue(
      syncId: 'team:$teamId',
      entityType: 'team',
      entityId: teamId,
    );
  }

  domain.Team _toDomain(Team row) {
    return domain.Team(
      id: row.id,
      name: row.name,
      shortName: row.shortName,
      logoPath: row.logoPath,
      isActive: row.isActive,
    );
  }
}
