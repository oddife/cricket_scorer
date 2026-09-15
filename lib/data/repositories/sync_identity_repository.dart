abstract interface class SyncIdentityRepository {
  Future<String> ensureMatchSyncId(int matchId);
  Future<String> ensureInningsSyncId(int inningsId);
  Future<String?> getMatchSyncId(int matchId);
  Future<String?> getInningsSyncId(int inningsId);
}
