import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'ball_event_deletion_repository.dart';

class DriftBallEventDeletionRepository implements BallEventDeletionRepository {
  DriftBallEventDeletionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> recordLocalDeletion({
    required String syncId,
    required int matchId,
    required int inningsId,
    required String matchSyncId,
    required String inningsSyncId,
    required int sequenceNumber,
    required String deletedByInstallationId,
  }) async {
    await _db.customStatement(
      '''INSERT INTO ball_event_deletions
        (sync_id, match_id, innings_id, match_sync_id, innings_sync_id,
         sequence_number, deleted_by_installation_id, status, deleted_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?)
      ON CONFLICT(sync_id) DO UPDATE SET
        match_id = excluded.match_id,
        innings_id = excluded.innings_id,
        match_sync_id = excluded.match_sync_id,
        innings_sync_id = excluded.innings_sync_id,
        sequence_number = excluded.sequence_number,
        deleted_by_installation_id = excluded.deleted_by_installation_id,
        status = CASE
          WHEN ball_event_deletions.status = 'synced' THEN 'synced'
          ELSE 'pending'
        END''',
      [
        syncId,
        matchId,
        inningsId,
        matchSyncId,
        inningsSyncId,
        sequenceNumber,
        deletedByInstallationId,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<List<BallEventDeletion>> getPending({int limit = 50}) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    final rows = await _db.customSelect(
      '''SELECT sync_id, match_id, innings_id, match_sync_id, innings_sync_id,
                sequence_number, deleted_by_installation_id, status, deleted_at
         FROM ball_event_deletions
         WHERE status = 'pending'
         ORDER BY deleted_at ASC, sync_id ASC
         LIMIT ?''',
      variables: [Variable.withInt(limit)],
    ).get();
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<BallEventDeletion>> getForMatch(int matchId) async {
    final rows = await _db.customSelect(
      '''SELECT sync_id, match_id, innings_id, match_sync_id, innings_sync_id,
                sequence_number, deleted_by_installation_id, status, deleted_at
         FROM ball_event_deletions
         WHERE match_id = ?
         ORDER BY sequence_number ASC, deleted_at ASC''',
      variables: [Variable.withInt(matchId)],
    ).get();
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> markSynced(String syncId) async {
    final updated = await _db.customUpdate(
      '''UPDATE ball_event_deletions
         SET status = 'synced'
         WHERE sync_id = ?''',
      variables: [Variable.withString(syncId)],
      updates: {},
    );
    if (updated != 1) {
      throw StateError('Ball event deletion $syncId was not found.');
    }
  }

  @override
  Future<void> recordRemoteDeletion({
    required String syncId,
    required int matchId,
    required int inningsId,
    required String matchSyncId,
    required String inningsSyncId,
    required int sequenceNumber,
    required String deletedByInstallationId,
    required DateTime deletedAt,
  }) async {
    await _db.customStatement(
      '''INSERT INTO ball_event_deletions
        (sync_id, match_id, innings_id, match_sync_id, innings_sync_id,
         sequence_number, deleted_by_installation_id, status, deleted_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'synced', ?)
      ON CONFLICT(sync_id) DO UPDATE SET
        match_id = excluded.match_id,
        innings_id = excluded.innings_id,
        match_sync_id = excluded.match_sync_id,
        innings_sync_id = excluded.innings_sync_id,
        sequence_number = excluded.sequence_number,
        deleted_by_installation_id = excluded.deleted_by_installation_id,
        status = 'synced',
        deleted_at = excluded.deleted_at''',
      [
        syncId,
        matchId,
        inningsId,
        matchSyncId,
        inningsSyncId,
        sequenceNumber,
        deletedByInstallationId,
        deletedAt.toUtc().toIso8601String(),
      ],
    );
  }

  BallEventDeletion _fromRow(QueryRow row) {
    final data = row.data;
    return BallEventDeletion(
      syncId: data['sync_id'] as String,
      matchId: data['match_id'] as int,
      inningsId: data['innings_id'] as int,
      matchSyncId: data['match_sync_id'] as String,
      inningsSyncId: data['innings_sync_id'] as String,
      sequenceNumber: data['sequence_number'] as int,
      deletedByInstallationId:
          data['deleted_by_installation_id'] as String,
      status: data['status'] as String,
      deletedAt: DateTime.parse(data['deleted_at'] as String),
    );
  }
}
