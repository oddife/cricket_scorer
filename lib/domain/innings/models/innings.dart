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
    this.activeTwoBowlerOneId,
    this.activeTwoBowlerTwoId,
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
  final int? activeTwoBowlerOneId;
  final int? activeTwoBowlerTwoId;
  final InningsStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  Innings withActiveTwoBowlerPair(List<int>? pair) {
    if (pair == null) {
      return copyWith();
    }
    if (pair.length != 2) {
      throw ArgumentError('Active two-bowler pair must contain exactly two bowlers.');
    }
    return Innings(
      id: id,
      matchId: matchId,
      inningsNumber: inningsNumber,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
      openingStrikerId: openingStrikerId,
      openingNonStrikerId: openingNonStrikerId,
      openingBowlerId: openingBowlerId,
      oversPerInnings: oversPerInnings,
      ballsPerOver: ballsPerOver,
      twoBowlerMode: twoBowlerMode,
      activeTwoBowlerOneId: pair[0],
      activeTwoBowlerTwoId: pair[1],
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  Innings withActiveFinalOverBowler(int bowlerId) => Innings(
        id: id,
        matchId: matchId,
        inningsNumber: inningsNumber,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        openingStrikerId: openingStrikerId,
        openingNonStrikerId: openingNonStrikerId,
        openingBowlerId: openingBowlerId,
        oversPerInnings: oversPerInnings,
        ballsPerOver: ballsPerOver,
        twoBowlerMode: twoBowlerMode,
        activeTwoBowlerOneId: bowlerId,
        activeTwoBowlerTwoId: null,
        status: status,
        startedAt: startedAt,
        completedAt: completedAt,
      );

  Innings clearActiveTwoBowlerPair() => Innings(
        id: id,
        matchId: matchId,
        inningsNumber: inningsNumber,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        openingStrikerId: openingStrikerId,
        openingNonStrikerId: openingNonStrikerId,
        openingBowlerId: openingBowlerId,
        oversPerInnings: oversPerInnings,
        ballsPerOver: ballsPerOver,
        twoBowlerMode: twoBowlerMode,
        status: status,
        startedAt: startedAt,
        completedAt: completedAt,
      );

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
    int? activeTwoBowlerOneId,
    int? activeTwoBowlerTwoId,
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
      openingNonStrikerId: openingNonStrikerId ?? this.openingNonStrikerId,
      openingBowlerId: openingBowlerId ?? this.openingBowlerId,
      oversPerInnings: oversPerInnings ?? this.oversPerInnings,
      ballsPerOver: ballsPerOver ?? this.ballsPerOver,
      twoBowlerMode: twoBowlerMode ?? this.twoBowlerMode,
      activeTwoBowlerOneId: activeTwoBowlerOneId ?? this.activeTwoBowlerOneId,
      activeTwoBowlerTwoId: activeTwoBowlerTwoId ?? this.activeTwoBowlerTwoId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
