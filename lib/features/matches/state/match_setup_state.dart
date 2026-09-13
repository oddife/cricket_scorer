import '../../../domain/matches/enums/toss_decision.dart';

class MatchSetupState {
  const MatchSetupState({
    this.name = '',
    this.date,
    this.venue = '',
    this.inningsCount = 2,
    this.oversPerInnings = 20,
    this.playersPerTeam = 11,
    this.twoBowlerMode = false,
    this.teamAId,
    this.teamBId,
    this.tossWinnerTeamId,
    this.tossDecision,
  });

  final String name;
  final DateTime? date;
  final String venue;
  final int inningsCount;
  final int oversPerInnings;
  final int playersPerTeam;
  final bool twoBowlerMode;
  final int? teamAId;
  final int? teamBId;
  final int? tossWinnerTeamId;
  final TossDecision? tossDecision;

  MatchSetupState copyWith({
    String? name,
    DateTime? date,
    String? venue,
    int? inningsCount,
    int? oversPerInnings,
    int? playersPerTeam,
    bool? twoBowlerMode,
    int? teamAId,
    int? teamBId,
    int? tossWinnerTeamId,
    TossDecision? tossDecision,
  }) {
    return MatchSetupState(
      name: name ?? this.name,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      inningsCount: inningsCount ?? this.inningsCount,
      oversPerInnings: oversPerInnings ?? this.oversPerInnings,
      playersPerTeam: playersPerTeam ?? this.playersPerTeam,
      twoBowlerMode: twoBowlerMode ?? this.twoBowlerMode,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      tossWinnerTeamId: tossWinnerTeamId ?? this.tossWinnerTeamId,
      tossDecision: tossDecision ?? this.tossDecision,
    );
  }
}
