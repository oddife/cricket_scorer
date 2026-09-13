class BowlerRotationContext {
  const BowlerRotationContext({
    required this.eligibleBowlerIds,
    required this.currentBowlerId,
    required this.legalBallsInCurrentOver,
    required this.ballsPerOver,
    required this.twoBowlerMode,
    required this.completedOvers,
    required this.isLegalBall,
    this.activeTwoBowlerIds = const <int>[],
    this.totalOvers = 0,
    this.isFinalOver = false,
  });

  final List<int> eligibleBowlerIds;
  final int currentBowlerId;
  final int legalBallsInCurrentOver;
  final int ballsPerOver;
  final bool twoBowlerMode;
  final int completedOvers;
  final bool isLegalBall;
  final List<int> activeTwoBowlerIds;
  final int totalOvers;
  final bool isFinalOver;
}
