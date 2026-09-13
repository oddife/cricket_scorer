import '../../domain/players/models/player.dart';
import '../../domain/teams/models/team_player.dart';

abstract interface class TeamPlayerRepository {
  Future<List<Player>> getPlayersForTeam(int teamId);
  Future<TeamPlayer> addPlayerToTeam({
    required int teamId,
    required int playerId,
    int? jerseyNumber,
  });
  Future<void> removePlayerFromTeam(int teamId, int playerId);
  Future<void> updateJerseyNumber(int teamId, int playerId, int? jerseyNumber);
}
