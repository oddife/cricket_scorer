class StrikeResult {
  const StrikeResult({
    required this.strikerId,
    required this.nonStrikerId,
    required this.overCompleted,
  });

  final int strikerId;
  final int nonStrikerId;
  final bool overCompleted;
}
