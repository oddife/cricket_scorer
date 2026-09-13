class StrikeContext {
  const StrikeContext({
    required this.strikerId,
    required this.nonStrikerId,
    required this.completedRuns,
    required this.isLegalBall,
    required this.isEndOfOver,
  });

  final int strikerId;
  final int nonStrikerId;
  final int completedRuns;
  final bool isLegalBall;
  final bool isEndOfOver;
}
