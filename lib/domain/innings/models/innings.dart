import '../enums/innings_status.dart';

class Innings {
  const Innings({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.openingStrikerId,
    required this.openingNonStrikerId,
    required this.openingBowlerId,
    required this.oversPerInnings,
    required this.ballsPerOver,
    required this.twoBowlerMode,
    this.status = InningsStatus.setup,
    this.startedAt,
    this.completedAt,
  });

  final int id;
  final int matchId;
  final int inningsNumber;
  final int battingTeamId;
  final int bowlingTeamId;
  final int openingStrikerId;
  final int openingNonStrikerId;
  final int openingBowlerId;
  final int oversPerInnings;
  final int ballsPerOver;
  final bool twoBowlerMode;
  final InningsStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  Innings copyWith({
    int? id,
    int? matchId,
    int? inningsNumber,
    int? battingTeamId,
    int? bowlingTeamId,
    int? openingStrikerId,
    int? openingNonStrikerId,
    int? openingBowlerId,
    int? oversPerInnings,
    int? ballsPerOver,
    bool? twoBowlerMode,
    InningsStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Innings(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      openingStrikerId: openingStrikerId ?? this.openingStrikerId,
      openingNonStrikerId:
          openingNonStrikerId ?? this.openingNonStrikerId,
      openingBowlerId: openingBowlerId ?? this.openingBowlerId,
      oversPerInnings: oversPerInnings ?? this.oversPerInnings,
      ballsPerOver: ballsPerOver ?? this.ballsPerOver,
      twoBowlerMode: twoBowlerMode ?? this.twoBowlerMode,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
