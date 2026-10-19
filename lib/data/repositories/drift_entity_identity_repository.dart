import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'entity_identity_repository.dart';

class DriftEntityIdentityRepository implements EntityIdentityRepository {
  DriftEntityIdentityRepository(this._db);

  final AppDatabase _db;
  final Random _random = Random.secure();

  @override
  Future<EntityIdentity> ensure(String entityType, int localId) async {
    final existing = await get(entityType, localId);
    if (existing != null) return existing;

    final appId = _newUuidV4();
    await _db.customStatement(
      '''INSERT INTO entity_identities
        (entity_type, local_id, app_id, global_id, created_at)
      VALUES (?, ?, ?, NULL, ?)
      ON CONFLICT(entity_type, local_id) DO NOTHING''',
      [entityType, localId, appId, DateTime.now().toIso8601String()],
    );

    return (await get(entityType, localId))!;
  }

  @override
  Future<EntityIdentity?> get(String entityType, int localId) async {
    final rows = await _db.customSelect(
      '''SELECT entity_type, local_id, app_id, global_id
         FROM entity_identities
         WHERE entity_type = ? AND local_id = ?
         LIMIT 1''',
      variables: [
        Variable.withString(entityType),
        Variable.withInt(localId),
      ],
    ).get();

    if (rows.isEmpty) return null;
    final row = rows.single.data;
    return EntityIdentity(
      entityType: row['entity_type'] as String,
      localId: row['local_id'] as int,
      appId: row['app_id'] as String,
      globalId: row['global_id'] as String?,
    );
  }

  @override
  Future<void> setGlobalId({
    required String entityType,
    required int localId,
    required String globalId,
  }) async {
    await _db.customStatement(
      '''UPDATE entity_identities
         SET global_id = ?
         WHERE entity_type = ? AND local_id = ?''',
      [globalId, entityType, localId],
    );
  }

  @override
  Future<void> adoptRemoteIdentity({
    required String entityType,
    required int localId,
    required String appId,
    required String globalId,
  }) async {
    await _db.customStatement(
      '''INSERT INTO entity_identities
        (entity_type, local_id, app_id, global_id, created_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(entity_type, local_id) DO UPDATE SET
        app_id = excluded.app_id,
        global_id = excluded.global_id''',
      [
        entityType,
        localId,
        appId,
        globalId,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  String _newUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
