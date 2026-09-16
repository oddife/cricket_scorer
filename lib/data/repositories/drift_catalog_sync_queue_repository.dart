import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'catalog_sync_queue_repository.dart';

class DriftCatalogSyncQueueRepository implements CatalogSyncQueueRepository {
  DriftCatalogSyncQueueRepository(this._db);
  final AppDatabase _db;

  @override
  Future<void> enqueue({required String syncId, required String entityType, required int entityId}) async {
    _validate(syncId, entityType, entityId);
    await _upsert(syncId, entityType, entityId, resetSynced: true);
  }

  @override
  Future<void> enqueueIfMissing({required String syncId, required String entityType, required int entityId}) async {
    _validate(syncId, entityType, entityId);
    await _upsert(syncId, entityType, entityId, resetSynced: false);
  }

  Future<void> _upsert(String syncId, String entityType, int entityId, {required bool resetSynced}) async {
    await _db.customStatement(
      '''INSERT INTO catalog_sync_queue
        (sync_id, entity_type, entity_id, status, attempts, created_at)
      VALUES (?, ?, ?, 'pending', 0, ?)
      ON CONFLICT(sync_id) DO UPDATE SET
        entity_type = excluded.entity_type,
        entity_id = excluded.entity_id,
        status = CASE WHEN ? = 1 AND catalog_sync_queue.status = 'synced' THEN 'pending' ELSE catalog_sync_queue.status END,
        next_attempt_at = CASE WHEN ? = 1 AND catalog_sync_queue.status = 'synced' THEN NULL ELSE catalog_sync_queue.next_attempt_at END,
        last_error = CASE WHEN ? = 1 AND catalog_sync_queue.status = 'synced' THEN NULL ELSE catalog_sync_queue.last_error END,
        synced_at = CASE WHEN ? = 1 AND catalog_sync_queue.status = 'synced' THEN NULL ELSE catalog_sync_queue.synced_at END''',
      [syncId, entityType, entityId, DateTime.now().toUtc().toIso8601String(),
        resetSynced ? 1 : 0, resetSynced ? 1 : 0, resetSynced ? 1 : 0, resetSynced ? 1 : 0],
    );
  }

  void _validate(String syncId, String entityType, int entityId) {
    if (syncId.isEmpty) throw ArgumentError.value(syncId, 'syncId');
    if (entityType.isEmpty) throw ArgumentError.value(entityType, 'entityType');
    if (entityId <= 0) throw ArgumentError.value(entityId, 'entityId');
  }

  @override
  Future<List<CatalogSyncQueueEntry>> getPending({int limit = 100}) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _db.customSelect('''
      SELECT id, sync_id, entity_type, entity_id, status, attempts, created_at,
             next_attempt_at, last_error, synced_at
      FROM catalog_sync_queue
      WHERE status IN ('pending', 'failed')
        AND (next_attempt_at IS NULL OR next_attempt_at <= ?)
      ORDER BY CASE entity_type WHEN 'team' THEN 0 WHEN 'player' THEN 1
        WHEN 'team_player' THEN 2 WHEN 'tournament' THEN 3 ELSE 4 END, id ASC
      LIMIT ?''', variables: [Variable.withString(now), Variable.withInt(limit)]).get();
    return rows.map(_entryFromRow).toList(growable: false);
  }

  @override
  Future<void> markInProgress(String syncId) async {
    final updated = await _db.customUpdate('''UPDATE catalog_sync_queue
      SET status = 'in_progress', attempts = attempts + 1, last_error = NULL
      WHERE sync_id = ? AND status IN ('pending', 'failed')''',
      variables: [Variable.withString(syncId)], updates: {});
    if (updated != 1) throw StateError('Catalog sync queue entry $syncId is not pending.');
  }

  @override
  Future<void> markSynced(String syncId) async {
    final updated = await _db.customUpdate('''UPDATE catalog_sync_queue
      SET status = 'synced', synced_at = ?, next_attempt_at = NULL, last_error = NULL
      WHERE sync_id = ?''', variables: [Variable.withString(DateTime.now().toUtc().toIso8601String()), Variable.withString(syncId)], updates: {});
    if (updated != 1) throw StateError('Catalog sync queue entry $syncId was not found.');
  }

  @override
  Future<void> markFailed(String syncId, {required String error, required DateTime nextAttemptAt}) async {
    final updated = await _db.customUpdate('''UPDATE catalog_sync_queue
      SET status = 'failed', last_error = ?, next_attempt_at = ? WHERE sync_id = ?''',
      variables: [Variable.withString(error), Variable.withString(nextAttemptAt.toUtc().toIso8601String()), Variable.withString(syncId)], updates: {});
    if (updated != 1) throw StateError('Catalog sync queue entry $syncId was not found.');
  }

  @override
  Future<void> resetInProgress() async {
    await _db.customStatement("UPDATE catalog_sync_queue SET status = 'pending' WHERE status = 'in_progress'");
  }

  CatalogSyncQueueEntry _entryFromRow(QueryRow row) {
    final data = row.data;
    return CatalogSyncQueueEntry(
      id: data['id'] as int, syncId: data['sync_id'] as String,
      entityType: data['entity_type'] as String, entityId: data['entity_id'] as int,
      status: data['status'] as String, attempts: data['attempts'] as int,
      createdAt: DateTime.parse(data['created_at'] as String),
      nextAttemptAt: _dateTimeOrNull(data['next_attempt_at']),
      lastError: data['last_error'] as String?, syncedAt: _dateTimeOrNull(data['synced_at']),
    );
  }

  DateTime? _dateTimeOrNull(Object? value) => value == null ? null : DateTime.parse(value as String);
}
