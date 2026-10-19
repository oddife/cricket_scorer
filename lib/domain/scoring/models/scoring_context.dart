class ScoringContext {
  const ScoringContext({
    required this.inningsId,
    required this.sequenceNumber,
    required this.overNumber,
    required this.legalBallsInCurrentOver,
    required this.ballsPerOver,
    required this.bowlerId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.timestamp,
  });

  final int inningsId;
  final int sequenceNumber;
  final int overNumber;
  final int legalBallsInCurrentOver;
  final int ballsPerOver;
  final int bowlerId;
  final int strikerId;
  final int nonStrikerId;
  final DateTime timestamp;
}
