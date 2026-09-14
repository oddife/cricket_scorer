import '../enums/delivery_type.dart';
import '../enums/run_out_end.dart';
import '../enums/wicket_type.dart';

/// Scorer input used to describe a wicket before it becomes part of a
/// persisted BallEvent.
class WicketInput {
  const WicketInput({
    required this.type,
    required this.dismissedPlayerId,
    this.fielderId,
    this.runOutEnd,
    this.completedRuns = 0,
    this.crossedBeforeWicket = false,
    this.replacementBatterId,
    this.deliveryType = DeliveryType.normal,
    this.batterRuns = 0,
    this.byeRuns = 0,
    this.legByeRuns = 0,
    this.wideRuns = 1,
    this.noBallRuns = 1,
  });

  final WicketType type;
  final int dismissedPlayerId;
  final int? fielderId;
  final RunOutEnd? runOutEnd;
  final int completedRuns;
  final bool crossedBeforeWicket;
  final int? replacementBatterId;

  /// The delivery on which the wicket occurred.
  final DeliveryType deliveryType;

  /// Additional runs recorded on the wicket delivery. For a no-ball this is
  /// batter/bye/leg-bye runs in addition to the mandatory no-ball penalty.
  final int batterRuns;
  final int byeRuns;
  final int legByeRuns;
  final int wideRuns;
  final int noBallRuns;
}
