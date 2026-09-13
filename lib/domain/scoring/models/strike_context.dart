class StrikeContext {
  const StrikeContext({
    required this.strikerId,
    required this.nonStrikerId,
    required this.legalBallCompleted,
    required this.ballsPerOver,
    required this.completedRuns,
  });

  final int strikerId;
  final int nonStrikerId;
  final bool legalBallCompleted;
  final int ballsPerOver;
  final int completedRuns;
}
