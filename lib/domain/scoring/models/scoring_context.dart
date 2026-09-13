class ScoringContext {
  const ScoringContext({
    required this.inningsId,
    required this.sequenceNumber,
    required this.legalBallsInCurrentOver,
    required this.bowlerId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.timestamp,
  });

  final int inningsId;
  final int sequenceNumber;
  final int legalBallsInCurrentOver;
  final int bowlerId;
  final int strikerId;
  final int nonStrikerId;
  final DateTime timestamp;
}
