class StrikeResult {
  const StrikeResult({
    required this.strikerId,
    required this.nonStrikerId,
    required this.swappedForRuns,
    required this.swappedAtEndOfOver,
  });

  final int strikerId;
  final int nonStrikerId;
  final bool swappedForRuns;
  final bool swappedAtEndOfOver;
}
