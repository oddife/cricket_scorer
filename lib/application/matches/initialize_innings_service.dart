import '../../domain/innings/enums/innings_status.dart';
import '../../domain/innings/models/innings.dart';
import '../../domain/matches/enums/match_team_slot.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/matches/models/match.dart';
import '../../domain/matches/models/match_player.dart';
import '../../domain/matches/models/match_team.dart';

class InitializeInningsService {
  const InitializeInningsService();

  Innings prepare({
    required Match match,
    required List<MatchTeam> matchTeams,
    required List<MatchPlayer> matchPlayers,
    required int inningsNumber,
    required int firstBowlerId,
  }) {
    final error = _validate(
      match: match,
      matchTeams: matchTeams,
      matchPlayers: matchPlayers,
      inningsNumber: inningsNumber,
      firstBowlerId: firstBowlerId,
    );
    if (error != null) throw ArgumentError(error);

    final teamA = matchTeams.firstWhere(
      (team) => team.slot == MatchTeamSlot.teamA,
    );
    final teamB = matchTeams.firstWhere(
      (team) => team.slot == MatchTeamSlot.teamB,
    );

    final battingTeamId = _battingTeamId(
      match: match,
      teamAId: teamA.teamId,
      teamBId: teamB.teamId,
      inningsNumber: inningsNumber,
    );
    final bowlingTeamId = battingTeamId == teamA.teamId
        ? teamB.teamId
        : teamA.teamId;

    final battingPlayers = matchPlayers
        .where(
          (player) =>
              player.teamId == battingTeamId && player.isPlaying,
        )
        .toList()
      ..sort(_byBattingOrder);

    return Innings(
      id: 0,
      matchId: match.id,
      inningsNumber: inningsNumber,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      openingStrikerId: battingPlayers[0].playerId,
      openingNonStrikerId: battingPlayers[1].playerId,
      openingBowlerId: firstBowlerId,
      oversPerInnings: match.oversPerInnings,
      ballsPerOver: match.ballsPerOver,
      twoBowlerMode: match.twoBowlerMode,
      status: InningsStatus.setup,
    );
  }

  String? _validate({
    required Match match,
    required List<MatchTeam> matchTeams,
    required List<MatchPlayer> matchPlayers,
    required int inningsNumber,
    required int firstBowlerId,
  }) {
    if (inningsNumber < 1 || inningsNumber > match.inningsCount) {
      return 'Innings number is outside the match innings count.';
    }

    final teamA = matchTeams.where(
      (team) => team.slot == MatchTeamSlot.teamA,
    );
    final teamB = matchTeams.where(
      (team) => team.slot == MatchTeamSlot.teamB,
    );
    if (teamA.length != 1 || teamB.length != 1) {
      return 'Both match teams are required before starting an innings.';
    }

    if (match.tossWinnerTeamId == null || match.tossDecision == null) {
      return 'Toss information is required before starting an innings.';
    }

    final teamAId = teamA.single.teamId;
    final teamBId = teamB.single.teamId;
    if (match.tossWinnerTeamId != teamAId &&
        match.tossWinnerTeamId != teamBId) {
      return 'Toss winner must belong to the match.';
    }

    final firstBattingTeamId = _firstBattingTeamId(
      tossWinnerTeamId: match.tossWinnerTeamId!,
      decision: match.tossDecision!,
    );
    if (inningsNumber == 1) {
      // Validated by _firstBattingTeamId.
    } else if (match.inningsCount != 4) {
      return 'Subsequent innings are only valid for a 4-innings match.';
    }

    final battingTeamId = inningsNumber.isOdd
        ? firstBattingTeamId
        : (firstBattingTeamId == teamAId ? teamBId : teamAId);
    final battingPlayers = matchPlayers
        .where(
          (player) =>
              player.teamId == battingTeamId && player.isPlaying,
        )
        .toList()
      ..sort(_byBattingOrder);

    if (battingPlayers.length < 2) {
      return 'At least two batting players are required.';
    }
    if (battingPlayers.any((player) => player.battingOrder == null)) {
      return 'Every Playing XI player must have a batting order.';
    }

    final bowlingTeamId = battingTeamId == teamAId ? teamBId : teamAId;
    final bowler = matchPlayers.where(
      (player) =>
          player.playerId == firstBowlerId &&
          player.teamId == bowlingTeamId &&
          player.isPlaying,
    );
    if (bowler.length != 1) {
      return 'First bowler must be an eligible player from the bowling XI.';
    }

    return null;
  }

  int _battingTeamId({
    required Match match,
    required int teamAId,
    required int teamBId,
    required int inningsNumber,
  }) {
    final firstBattingTeamId = _firstBattingTeamId(
      tossWinnerTeamId: match.tossWinnerTeamId!,
      decision: match.tossDecision!,
    );
    if (inningsNumber.isOdd) return firstBattingTeamId;
    return firstBattingTeamId == teamAId ? teamBId : teamAId;
  }

  int _firstBattingTeamId({
    required int tossWinnerTeamId,
    required TossDecision decision,
  }) {
    if (decision == TossDecision.bat) return tossWinnerTeamId;
    throw ArgumentError('Toss decision could not determine the first innings.');
  }

  int _byBattingOrder(MatchPlayer a, MatchPlayer b) {
    final aOrder = a.battingOrder ?? 1 << 30;
    final bOrder = b.battingOrder ?? 1 << 30;
    return aOrder.compareTo(bOrder);
  }
}
