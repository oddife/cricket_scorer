import '../enums/match_team_slot.dart';

class MatchTeam {
  const MatchTeam({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.slot,
  });

  final int id;
  final int matchId;
  final int teamId;
  final MatchTeamSlot slot;
}
