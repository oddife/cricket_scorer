import 'package:drift/drift.dart';

import '../../domain/tournaments/enums/tournament_type.dart';
import '../../domain/tournaments/models/tournament.dart' as domain;
import '../database/app_database.dart';
import 'tournament_repository.dart';

class DriftTournamentRepository implements TournamentRepository {
  DriftTournamentRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Tournament>> getAll() async {
    final rows = await (_database.select(_database.tournaments)
          ..where((table) => table.isActive.equals(true))
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .get();

    return rows.map<domain.Tournament>(_toDomain).toList(growable: false);
  }

  @override
  Future<domain.Tournament> create(domain.Tournament tournament) async {
    final now = DateTime.now();
    final id = await _database.into(_database.tournaments).insert(
          TournamentsCompanion.insert(
            name: tournament.name.trim(),
            tournamentType: tournament.type.dbValue,
            logoPath: Value(tournament.logoPath),
            startDate: Value(tournament.startDate),
            endDate: Value(tournament.endDate),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return tournament.copyWith(id: id, isActive: true);
  }

  @override
  Future<void> update(domain.Tournament tournament) async {
    await (_database.update(_database.tournaments)
          ..where((table) => table.id.equals(tournament.id)))
        .write(
      TournamentsCompanion(
        name: Value(tournament.name.trim()),
        tournamentType: Value(tournament.type.dbValue),
        logoPath: Value(tournament.logoPath),
        startDate: Value(tournament.startDate),
        endDate: Value(tournament.endDate),
        isActive: Value(tournament.isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deactivate(int tournamentId) async {
    await (_database.update(_database.tournaments)
          ..where((table) => table.id.equals(tournamentId)))
        .write(
      TournamentsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  domain.Tournament _toDomain(Tournament row) {
    return domain.Tournament(
      id: row.id,
      name: row.name,
      type: tournamentTypeFromDbValue(row.tournamentType),
      logoPath: row.logoPath,
      startDate: row.startDate,
      endDate: row.endDate,
      isActive: row.isActive,
    );
  }
}
