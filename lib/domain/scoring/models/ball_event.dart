import '../enums/delivery_type.dart';
import '../enums/run_out_end.dart';
import '../enums/wicket_type.dart';
import 'wicket.dart';

class BallEvent {
  const BallEvent({
    required this.id,
    required this.inningsId,
    required this.sequenceNumber,
    required this.overNumber,
    required this.legalBallNumber,
    required this.bowlerId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.deliveryType,
    required this.isLegalBall,
    required this.batterRuns,
    required this.byeRuns,
    required this.legByeRuns,
    required this.wideRuns,
    required this.noBallRuns,
    required this.totalRuns,
    this.wicket,
    required this.timestamp,
  });

  final int id;
  final int inningsId;
  final int sequenceNumber;
  final int overNumber;
  final int legalBallNumber;
  final int bowlerId;
  final int strikerId;
  final int nonStrikerId;
  final DeliveryType deliveryType;
  final bool isLegalBall;
  final int batterRuns;
  final int byeRuns;
  final int legByeRuns;
  final int wideRuns;
  final int noBallRuns;
  final int totalRuns;
  final Wicket? wicket;
  final DateTime timestamp;

  bool get hasWicket => wicket != null;

  bool get isBoundary =>
      batterRuns == 4 || batterRuns == 6;

  bool get isRunOut => wicket?.type == WicketType.runOut;

  bool get isOverFence => wicket?.type == WicketType.overFence;

  bool get hasRunOutEnd => wicket?.runOutEnd != null;

  RunOutEnd? get runOutEnd => wicket?.runOutEnd;
}
