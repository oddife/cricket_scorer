import 'package:drift/drift.dart';

import '../../domain/tournaments/enums/tournament_type.dart';
import '../../domain/tournaments/models/tournament.dart' as domain;
import '../database/app_database.dart';
import 'catalog_sync_queue_repository.dart';
import 'sync_identity_repository.dart';
import 'tournament_repository.dart';

class DriftTournamentRepository implements TournamentRepository {
  DriftTournamentRepository(
    this._database, [
    this._catalogSyncQueueRepository,
    this._syncIdentityRepository,
  ]);

  final AppDatabase _database;
  final CatalogSyncQueueRepository? _catalogSyncQueueRepository;
  final SyncIdentityRepository? _syncIdentityRepository;

  @override
  Future<List<domain.Tournament>> getAll() async => _readTournaments(activeOnly: true);

  Future<List<domain.Tournament>> getAllIncludingInactive() async =>
      _readTournaments(activeOnly: false);

  Future<List<domain.Tournament>> _readTournaments({required bool activeOnly}) async {
    final query = _database.select(_database.tournaments);
    if (activeOnly) query.where((table) => table.isActive.equals(true));
    query.orderBy([(table) => OrderingTerm.desc(table.createdAt)]);
    final rows = await query.get();
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
    final created = tournament.copyWith(id: id, isActive: true);
    await _enqueue(id);
    return created;
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
    await _enqueue(tournament.id);
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
    await _enqueue(tournamentId);
  }

  Future<void> _enqueue(int tournamentId) async {
    final queue = _catalogSyncQueueRepository;
    final identity = _syncIdentityRepository;
    if (queue == null || identity == null) return;
    await queue.enqueue(
      syncId: await identity.ensureTournamentSyncId(tournamentId),
      entityType: 'tournament',
      entityId: tournamentId,
    );
  }

  domain.Tournament _toDomain(Tournament row) => domain.Tournament(
        id: row.id,
        name: row.name,
        type: tournamentTypeFromDbValue(row.tournamentType),
        logoPath: row.logoPath,
        startDate: row.startDate,
        endDate: row.endDate,
        isActive: row.isActive,
      );
}
