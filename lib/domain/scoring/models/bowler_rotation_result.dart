class BowlerRotationResult {
  const BowlerRotationResult({
    required this.currentBowlerId,
    required this.completedOver,
    required this.legalBallsInCurrentOver,
    required this.twoBowlerBlockCompleted,
  });

  final int currentBowlerId;
  final bool completedOver;
  final int legalBallsInCurrentOver;
  final bool twoBowlerBlockCompleted;
}
