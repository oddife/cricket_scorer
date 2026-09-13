import '../enums/match_status.dart';
import '../enums/toss_decision.dart';

class Match {
  const Match({
    required this.id,
    required this.name,
    required this.date,
    required this.inningsCount,
    required this.oversPerInnings,
    required this.ballsPerOver,
    required this.playersPerTeam,
    required this.twoBowlerMode,
    this.tournamentId,
    this.venue,
    this.tossWinnerTeamId,
    this.tossDecision,
    this.status = MatchStatus.setup,
  });

  final int id;
  final int? tournamentId;
  final String name;
  final DateTime date;
  final String? venue;
  final int inningsCount;
  final int oversPerInnings;
  final int ballsPerOver;
  final int playersPerTeam;
  final bool twoBowlerMode;
  final int? tossWinnerTeamId;
  final TossDecision? tossDecision;
  final MatchStatus status;

  Match copyWith({
    int? id,
    int? tournamentId,
    String? name,
    DateTime? date,
    String? venue,
    int? inningsCount,
    int? oversPerInnings,
    int? ballsPerOver,
    int? playersPerTeam,
    bool? twoBowlerMode,
    int? tossWinnerTeamId,
    TossDecision? tossDecision,
    MatchStatus? status,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      inningsCount: inningsCount ?? this.inningsCount,
      oversPerInnings: oversPerInnings ?? this.oversPerInnings,
      ballsPerOver: ballsPerOver ?? this.ballsPerOver,
      playersPerTeam: playersPerTeam ?? this.playersPerTeam,
      twoBowlerMode: twoBowlerMode ?? this.twoBowlerMode,
      tossWinnerTeamId: tossWinnerTeamId ?? this.tossWinnerTeamId,
      tossDecision: tossDecision ?? this.tossDecision,
      status: status ?? this.status,
    );
  }
}
