import 'package:drift/drift.dart';

import '../../domain/players/models/player.dart' as domain;
import '../database/app_database.dart';
import '../database/tables/players.dart';
import 'player_repository.dart';

class DriftPlayerRepository implements PlayerRepository {
  DriftPlayerRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Player>> getAll() async {
    final rows = await (_database.select(_database.players)
          ..where((row) => row.isActive.equals(true))
          ..orderBy([(row) => OrderingTerm.asc(row.displayName)]))
        .get();
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
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return player.copyWith(id: id, isActive: true);
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
        isActive: Value(player.isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
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
  }

  domain.Player _toDomain(Player row) {
    return domain.Player(
      id: row.id,
      name: row.name,
      displayName: row.displayName,
      photoPath: row.photoPath,
      isActive: row.isActive,
    );
  }
}
