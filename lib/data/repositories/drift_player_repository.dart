import 'package:drift/drift.dart';

import '../../domain/players/enums/batting_style.dart';
import '../../domain/players/enums/bowling_style.dart';
import '../../domain/players/models/player.dart' as domain;
import '../database/app_database.dart';
import 'catalog_sync_queue_repository.dart';
import 'player_repository.dart';
import 'sync_identity_repository.dart';

class DriftPlayerRepository implements PlayerRepository {
  DriftPlayerRepository(
    this._database, [
    this._catalogSyncQueueRepository,
    this._syncIdentityRepository,
  ]);

  final AppDatabase _database;
  final CatalogSyncQueueRepository? _catalogSyncQueueRepository;
  final SyncIdentityRepository? _syncIdentityRepository;

  @override
  Future<List<domain.Player>> getAll() async => _readPlayers(activeOnly: true);

  @override
  Future<List<domain.Player>> getAllIncludingInactive() async =>
      _readPlayers(activeOnly: false);

  Future<List<domain.Player>> _readPlayers({required bool activeOnly}) async {
    final query = _database.select(_database.players);
    if (activeOnly) query.where((row) => row.isActive.equals(true));
    query.orderBy([(row) => OrderingTerm.asc(row.displayName)]);
    final rows = await query.get();
    return rows.map<domain.Player>(_toDomain).toList(growable: false);
  }

  @override
  Future<domain.Player> create(domain.Player player) async {
    final now = DateTime.now();
    final id = await _database.into(_database.players).insert(
          PlayersCompanion.insert(
            name: player.name,
            displayName: player.displayName,
            photoPath: Value(player.photoPath),
            jerseyNumber: Value(player.jerseyNumber),
            battingStyle: Value(player.battingStyle.dbValue),
            bowlingStyle: Value(player.bowlingStyle.dbValue),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final created = player.copyWith(id: id, isActive: true);
    await _enqueue(id);
    return created;
  }

  @override
  Future<void> update(domain.Player player) async {
    await (_database.update(_database.players)
          ..where((row) => row.id.equals(player.id)))
        .write(
      PlayersCompanion(
        name: Value(player.name),
        displayName: Value(player.displayName),
        photoPath: Value(player.photoPath),
        jerseyNumber: Value(player.jerseyNumber),
        battingStyle: Value(player.battingStyle.dbValue),
        bowlingStyle: Value(player.bowlingStyle.dbValue),
        isActive: Value(player.isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _enqueue(player.id);
  }

  @override
  Future<void> deactivate(int playerId) async {
    await (_database.update(_database.players)
          ..where((row) => row.id.equals(playerId)))
        .write(
      PlayersCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _enqueue(playerId);
  }

  Future<void> _enqueue(int playerId) async {
    final queue = _catalogSyncQueueRepository;
    final identity = _syncIdentityRepository;
    if (queue == null || identity == null) return;
    await queue.enqueue(
      syncId: await identity.ensurePlayerSyncId(playerId),
      entityType: 'player',
      entityId: playerId,
    );
  }

  domain.Player _toDomain(Player row) => domain.Player(
        id: row.id,
        name: row.name,
        displayName: row.displayName,
        photoPath: row.photoPath,
        jerseyNumber: row.jerseyNumber,
        battingStyle: battingStyleFromDbValue(row.battingStyle),
        bowlingStyle: bowlingStyleFromDbValue(row.bowlingStyle),
        isActive: row.isActive,
      );
}
