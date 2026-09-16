import 'package:drift/drift.dart';

import '../../domain/teams/models/team.dart' as domain;
import '../database/app_database.dart';
import 'team_repository.dart';

class DriftTeamRepository implements TeamRepository {
  DriftTeamRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Team>> getAll() async {
    final rows = await (_database.select(_database.teams)
          ..where((row) => row.isActive.equals(true))
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .get();
    return rows.map<domain.Team>(_toDomain).toList(growable: false);
  }

  @override
  Future<List<domain.Team>> getAllIncludingInactive() async {
    final rows = await (_database.select(_database.teams)
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .get();
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
    return domain.Team(
      id: id,
      name: team.name,
      shortName: team.shortName,
      logoPath: team.logoPath,
      isActive: true,
    );
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
