abstract interface class SyncIdentityRepository {
  Future<String> ensureMatchSyncId(int matchId);
  Future<String> ensureInningsSyncId(int inningsId);
  Future<String> ensureBallEventSyncId(int ballEventId);
  Future<String> ensureTeamSyncId(int teamId);
  Future<String> ensurePlayerSyncId(int playerId);
  Future<String> ensureTeamPlayerSyncId(int teamPlayerId);
  Future<String?> getMatchSyncId(int matchId);
  Future<String?> getInningsSyncId(int inningsId);
  Future<String?> getBallEventSyncId(int ballEventId);
  Future<String?> getTeamSyncId(int teamId);
  Future<String?> getPlayerSyncId(int playerId);
  Future<String?> getTeamPlayerSyncId(int teamPlayerId);
}
