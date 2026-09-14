import '../enums/run_out_end.dart';
import '../enums/wicket_type.dart';

class Wicket {
  const Wicket({
    required this.type,
    required this.dismissedPlayerId,
    this.fielderId,
    this.runOutEnd,
    this.completedRuns = 0,
    this.crossedBeforeWicket = false,
    this.replacementBatterId,
    required this.creditedToBowler,
  });

  final WicketType type;
  final int dismissedPlayerId;
  final int? fielderId;
  final RunOutEnd? runOutEnd;
  final int completedRuns;
  final bool crossedBeforeWicket;
  final int? replacementBatterId;
  final bool creditedToBowler;
}
