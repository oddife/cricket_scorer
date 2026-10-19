class InningsStartState {
  const InningsStartState({
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.firstBowlerId,
    required this.oversPerInnings,
    required this.ballsPerOver,
    required this.twoBowlerMode,
  });

  final int inningsNumber;
  final int battingTeamId;
  final int bowlingTeamId;
  final int strikerId;
  final int nonStrikerId;
  final int firstBowlerId;
  final int oversPerInnings;
  final int ballsPerOver;
  final bool twoBowlerMode;

  int get maximumLegalBalls => oversPerInnings * ballsPerOver;
}
