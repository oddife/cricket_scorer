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
  });

  final WicketType type;
  final int dismissedPlayerId;
  final int? fielderId;
  final RunOutEnd? runOutEnd;
  final int completedRuns;
  final bool crossedBeforeWicket;
  final int? replacementBatterId;
}
