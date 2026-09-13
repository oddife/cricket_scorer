class BowlerRotationContext {
  const BowlerRotationContext({
    required this.eligibleBowlerIds,
    required this.currentBowlerId,
    required this.legalBallsInCurrentOver,
    required this.ballsPerOver,
    required this.twoBowlerMode,
    required this.completedOvers,
    this.previousTwoBowlerIds = const <int>[],
  });

  final List<int> eligibleBowlerIds;
  final int currentBowlerId;
  final int legalBallsInCurrentOver;
  final int ballsPerOver;
  final bool twoBowlerMode;
  final int completedOvers;
  final List<int> previousTwoBowlerIds;
}
