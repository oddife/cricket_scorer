import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'sync_queue_repository.dart';

class DriftSyncQueueRepository implements SyncQueueRepository {
  DriftSyncQueueRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String> ensureInstallationId() async {
    final rows = await _db.customSelect(
      'SELECT installation_id FROM sync_metadata WHERE id = 1',
    ).get();
    if (rows.isNotEmpty) return rows.single.data['installation_id'] as String;

    final installationId = _newInstallationId();
    await _db.customStatement(
      'INSERT INTO sync_metadata (id, installation_id) VALUES (1, ?)',
      [installationId],
    );
    return installationId;
  }

  @override
  Future<void> enqueueBallEvent({
    required int ballEventId,
    required int inningsId,
    required int sequenceNumber,
  }) async {
    if (ballEventId <= 0) throw ArgumentError.value(ballEventId, 'ballEventId');
    if (inningsId <= 0) throw ArgumentError.value(inningsId, 'inningsId');
    if (sequenceNumber <= 0) {
      throw ArgumentError.value(sequenceNumber, 'sequenceNumber');
    }

    final installationId = await ensureInstallationId();
    final syncId = '$installationId:ball:$ballEventId';
    final now = DateTime.now().toUtc();

    await _db.customStatement(
      '''
      INSERT OR IGNORE INTO sync_queue
        (sync_id, entity_type, entity_id, innings_id, sequence_number,
         status, attempts, created_at)
      VALUES (?, 'ball_event', ?, ?, ?, 'pending', 0, ?)
      ''',
      [
        syncId,
        ballEventId,
        inningsId,
        sequenceNumber,
        now.toIso8601String(),
      ],
    );
  }

  @override
  Future<List<SyncQueueEntry>> getPending({int limit = 50}) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _db.customSelect(
      '''
      SELECT id, sync_id, entity_type, entity_id, innings_id, sequence_number,
             status, attempts, created_at, next_attempt_at, last_error, synced_at
      FROM sync_queue
      WHERE status IN ('pending', 'failed')
        AND (next_attempt_at IS NULL OR next_attempt_at <= ?)
      ORDER BY innings_id ASC, sequence_number ASC, id ASC
      LIMIT ?
      ''',
      variables: [Variable.withString(now), Variable.withInt(limit)],
    ).get();
    return rows.map(_entryFromRow).toList(growable: false);
  }

  @override
  Future<void> markInProgress(String syncId) async {
    final updated = await _db.customUpdate(
      '''
      UPDATE sync_queue
      SET status = 'in_progress', attempts = attempts + 1, last_error = NULL
      WHERE sync_id = ? AND status IN ('pending', 'failed')
      ''',
      variables: [Variable.withString(syncId)],
      updates: {},
    );
    if (updated != 1) {
      throw StateError('Sync queue entry $syncId is not pending.');
    }
  }

  @override
  Future<void> markSynced(String syncId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = await _db.customUpdate(
      '''
      UPDATE sync_queue
      SET status = 'synced', synced_at = ?, next_attempt_at = NULL, last_error = NULL
      WHERE sync_id = ?
      ''',
      variables: [Variable.withString(now), Variable.withString(syncId)],
      updates: {},
    );
    if (updated != 1) throw StateError('Sync queue entry $syncId was not found.');
  }

  @override
  Future<void> markFailed(
    String syncId, {
    required String error,
    required DateTime nextAttemptAt,
  }) async {
    final updated = await _db.customUpdate(
      '''
      UPDATE sync_queue
      SET status = 'failed', last_error = ?, next_attempt_at = ?
      WHERE sync_id = ?
      ''',
      variables: [
        Variable.withString(error),
        Variable.withString(nextAttemptAt.toUtc().toIso8601String()),
        Variable.withString(syncId),
      ],
      updates: {},
    );
    if (updated != 1) throw StateError('Sync queue entry $syncId was not found.');
  }

  @override
  Future<void> resetInProgress() async {
    await _db.customStatement('''
      UPDATE sync_queue
      SET status = 'pending'
      WHERE status = 'in_progress'
    ''');
  }

  SyncQueueEntry _entryFromRow(QueryRow row) {
    final data = row.data;
    return SyncQueueEntry(
      id: data['id'] as int,
      syncId: data['sync_id'] as String,
      entityType: data['entity_type'] as String,
      entityId: data['entity_id'] as int,
      inningsId: data['innings_id'] as int,
      sequenceNumber: data['sequence_number'] as int,
      status: data['status'] as String,
      attempts: data['attempts'] as int,
      createdAt: DateTime.parse(data['created_at'] as String),
      nextAttemptAt: _dateTimeOrNull(data['next_attempt_at']),
      lastError: data['last_error'] as String?,
      syncedAt: _dateTimeOrNull(data['synced_at']),
    );
  }

  DateTime? _dateTimeOrNull(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  String _newInstallationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return 'inst_$hex';
  }
}
