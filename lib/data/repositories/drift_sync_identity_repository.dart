import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'sync_identity_repository.dart';

class DriftSyncIdentityRepository implements SyncIdentityRepository {
  DriftSyncIdentityRepository(this._db);

  final AppDatabase _db;
  final Random _random = Random.secure();

  @override
  Future<String> ensureMatchSyncId(int matchId) => _ensure('match', matchId);

  @override
  Future<String> ensureInningsSyncId(int inningsId) =>
      _ensure('innings', inningsId);

  @override
  Future<String> ensureBallEventSyncId(int ballEventId) =>
      _ensure('ball', ballEventId);

  @override
  Future<String> ensureTeamSyncId(int teamId) => _ensure('team', teamId);

  @override
  Future<String> ensurePlayerSyncId(int playerId) => _ensure('player', playerId);

  @override
  Future<String> ensureTeamPlayerSyncId(int teamPlayerId) =>
      _ensure('team_player', teamPlayerId);

  @override
  Future<String?> getMatchSyncId(int matchId) => _get('match', matchId);

  @override
  Future<String?> getInningsSyncId(int inningsId) => _get('innings', inningsId);

  @override
  Future<String?> getBallEventSyncId(int ballEventId) => _get('ball', ballEventId);

  @override
  Future<String?> getTeamSyncId(int teamId) => _get('team', teamId);

  @override
  Future<String?> getPlayerSyncId(int playerId) => _get('player', playerId);

  @override
  Future<String?> getTeamPlayerSyncId(int teamPlayerId) =>
      _get('team_player', teamPlayerId);

  Future<String> _ensure(String entityType, int localId) async {
    final existing = await _get(entityType, localId);
    if (existing != null) return existing;

    final syncId = _newSyncId();
    await _db.customStatement(
      '''
      INSERT INTO sync_entity_identities
        (entity_type, local_id, sync_id, created_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(entity_type, local_id) DO NOTHING
      ''',
      [entityType, localId, syncId, DateTime.now().toIso8601String()],
    );

    return (await _get(entityType, localId))!;
  }

  Future<String?> _get(String entityType, int localId) async {
    final rows = await _db.customSelect(
      '''
      SELECT sync_id
      FROM sync_entity_identities
      WHERE entity_type = ? AND local_id = ?
      LIMIT 1
      ''',
      variables: [
        Variable.withString(entityType),
        Variable.withInt(localId),
      ],
    ).get();
    if (rows.isEmpty) return null;
    return rows.single.data['sync_id'] as String;
  }

  String _newSyncId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
