class BallEventDeletion {
  const BallEventDeletion({
    required this.syncId,
    required this.matchId,
    required this.inningsId,
    required this.matchSyncId,
    required this.inningsSyncId,
    required this.sequenceNumber,
    required this.deletedByInstallationId,
    required this.status,
    required this.deletedAt,
  });

  final String syncId;
  final int matchId;
  final int inningsId;
  final String matchSyncId;
  final String inningsSyncId;
  final int sequenceNumber;
  final String deletedByInstallationId;
  final String status;
  final DateTime deletedAt;
}

abstract interface class BallEventDeletionRepository {
  Future<void> recordLocalDeletion({
    required String syncId,
    required int matchId,
    required int inningsId,
    required String matchSyncId,
    required String inningsSyncId,
    required int sequenceNumber,
    required String deletedByInstallationId,
  });

  Future<List<BallEventDeletion>> getPending({int limit = 50});

  Future<List<BallEventDeletion>> getForMatch(int matchId);

  Future<void> markSynced(String syncId);

  Future<void> recordRemoteDeletion({
    required String syncId,
    required int matchId,
    required int inningsId,
    required String matchSyncId,
    required String inningsSyncId,
    required int sequenceNumber,
    required String deletedByInstallationId,
    required DateTime deletedAt,
  });
}
