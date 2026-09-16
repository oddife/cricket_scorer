class CatalogSyncQueueEntry {
  const CatalogSyncQueueEntry({
    required this.id,
    required this.syncId,
    required this.entityType,
    required this.entityId,
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
  final String status;
  final int attempts;
  final DateTime createdAt;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime? syncedAt;
}

abstract interface class CatalogSyncQueueRepository {
  Future<void> enqueue({
    required String syncId,
    required String entityType,
    required int entityId,
  });

  Future<void> enqueueIfMissing({
    required String syncId,
    required String entityType,
    required int entityId,
  });

  Future<List<CatalogSyncQueueEntry>> getPending({int limit = 100});
  Future<void> markInProgress(String syncId);
  Future<void> markSynced(String syncId);
  Future<void> markFailed(
    String syncId, {
    required String error,
    required DateTime nextAttemptAt,
  });
  Future<void> resetInProgress();
}
