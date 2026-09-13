import '../../domain/matches/enums/match_team_slot.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/matches/models/match.dart';
import '../../domain/matches/models/match_player.dart';
import '../../domain/matches/models/match_team.dart';

abstract interface class MatchRepository {
  Future<List<Match>> getAll();
  Future<Match?> getById(int matchId);
  Future<Match> create(Match match);
  Future<void> update(Match match);
  Future<void> delete(int matchId);

  Future<void> setTeam({
    required int matchId,
    required int teamId,
    required MatchTeamSlot slot,
  });
  Future<void> removeTeam(int matchId, MatchTeamSlot slot);
  Future<List<MatchTeam>> getTeams(int matchId);

  Future<void> addPlayer({
    required int matchId,
    required int teamId,
    required int playerId,
  });
  Future<void> removePlayer(int matchId, int playerId);
  Future<void> setPlayingXi({
    required int matchId,
    required int teamId,
    required List<int> playerIds,
  });
  Future<List<MatchPlayer>> getPlayers(int matchId);

  Future<void> setToss({
    required int matchId,
    required int tossWinnerTeamId,
    required TossDecision decision,
  });
}
