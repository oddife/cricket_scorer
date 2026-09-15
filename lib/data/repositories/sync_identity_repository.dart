abstract interface class SyncIdentityRepository {
  Future<String> ensureMatchSyncId(int matchId);
  Future<String> ensureInningsSyncId(int inningsId);
  Future<String> ensureBallEventSyncId(int ballEventId);
  Future<String?> getMatchSyncId(int matchId);
  Future<String?> getInningsSyncId(int inningsId);
  Future<String?> getBallEventSyncId(int ballEventId);
}
