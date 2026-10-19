class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.syncId,
    required this.entityType,
    required this.entityId,
    required this.inningsId,
    required this.sequenceNumber,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.nextAttemptAt,
    this.lastError,
    this.syncedAt,
  });

  final int id;
  final String syncId;
  final String entityType;
  final int entityId;
  final int inningsId;
  final int sequenceNumber;
  final String status;
  final int attempts;
  final DateTime createdAt;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime? syncedAt;
}

abstract interface class SyncQueueRepository {
  Future<String> ensureInstallationId();

  Future<void> enqueueBallEvent({
    required int ballEventId,
    required int inningsId,
    required int sequenceNumber,
  });

  Future<List<SyncQueueEntry>> getPending({int limit = 50});

  Future<void> markInProgress(String syncId);

  Future<void> markSynced(String syncId);

  Future<void> markFailed(
    String syncId, {
    required String error,
    required DateTime nextAttemptAt,
  });

  Future<void> resetInProgress();
}
