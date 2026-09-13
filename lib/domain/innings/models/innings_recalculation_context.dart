import '../../scoring/models/ball_event.dart';

class InningsRecalculationContext {
  const InningsRecalculationContext({
    required this.balls,
    required this.initialStrikerId,
    required this.initialNonStrikerId,
    required this.initialBowlerId,
    required this.ballsPerOver,
    this.totalOvers,
    this.maxWickets,
    this.target,
  });

  final List<BallEvent> balls;
  final int initialStrikerId;
  final int initialNonStrikerId;
  final int initialBowlerId;
  final int ballsPerOver;
  final int? totalOvers;
  final int? maxWickets;
  final int? target;
}
