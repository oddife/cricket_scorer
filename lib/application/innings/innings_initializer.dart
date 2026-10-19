import '../../domain/innings/models/innings_start_state.dart';
import '../../domain/matches/enums/match_team_slot.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/matches/models/match.dart';
import '../../domain/matches/models/match_player.dart';
import '../../domain/matches/models/match_team.dart';

class InningsInitializer {
  const InningsInitializer();

  InningsStartState initialize({
    required Match match,
    required List<MatchTeam> teams,
    required List<MatchPlayer> players,
    required int firstBowlerId,
    int inningsNumber = 1,
  }) {
    if (inningsNumber < 1 || inningsNumber > match.inningsCount) {
      throw ArgumentError('Innings number is outside the match configuration.');
    }
    if (match.tossWinnerTeamId == null || match.tossDecision == null) {
      throw ArgumentError('Toss winner and decision are required.');
    }

    final teamA = _teamForSlot(teams, MatchTeamSlot.teamA);
    final teamB = _teamForSlot(teams, MatchTeamSlot.teamB);

    final firstBattingTeamId = _battingTeamFromToss(
      teamAId: teamA.teamId,
      teamBId: teamB.teamId,
      tossWinnerTeamId: match.tossWinnerTeamId!,
      tossDecision: match.tossDecision!,
    );

    final battingTeamId = inningsNumber.isOdd
        ? firstBattingTeamId
        : (firstBattingTeamId == teamA.teamId ? teamB.teamId : teamA.teamId);
    final bowlingTeamId = battingTeamId == teamA.teamId ? teamB.teamId : teamA.teamId;

    final battingOrder = players
        .where((player) => player.teamId == battingTeamId && player.isPlaying)
        .where((player) => player.battingOrder != null)
        .toList()
      ..sort((a, b) => a.battingOrder!.compareTo(b.battingOrder!));

    if (battingOrder.length < 2) {
      throw ArgumentError('At least two batting-order players are required.');
    }

    final bowlingPlayers = players.where(
      (player) => player.teamId == bowlingTeamId && player.isPlaying,
    );
    if (!bowlingPlayers.any((player) => player.playerId == firstBowlerId)) {
      throw ArgumentError('First bowler must be in the bowling team Playing XI.');
    }

    return InningsStartState(
      inningsNumber: inningsNumber,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      strikerId: battingOrder[0].playerId,
      nonStrikerId: battingOrder[1].playerId,
      firstBowlerId: firstBowlerId,
      oversPerInnings: match.oversPerInnings,
      ballsPerOver: match.ballsPerOver,
      twoBowlerMode: match.twoBowlerMode,
    );
  }

  MatchTeam _teamForSlot(List<MatchTeam> teams, MatchTeamSlot slot) {
    for (final team in teams) {
      if (team.slot == slot) return team;
    }
    throw ArgumentError('Both match teams are required.');
  }

  int _battingTeamFromToss({
    required int teamAId,
    required int teamBId,
    required int tossWinnerTeamId,
    required TossDecision tossDecision,
  }) {
    if (tossWinnerTeamId != teamAId && tossWinnerTeamId != teamBId) {
      throw ArgumentError('Toss winner must be one of the match teams.');
    }
    if (tossDecision == TossDecision.bat) return tossWinnerTeamId;
    return tossWinnerTeamId == teamAId ? teamBId : teamAId;
  }
}
