import '../models/strike_context.dart';
import '../models/strike_result.dart';

class StrikeEngine {
  const StrikeEngine();

  StrikeResult apply(StrikeContext context) {
    if (context.strikerId <= 0 || context.nonStrikerId <= 0) {
      throw ArgumentError('Striker and non-striker IDs must be positive.');
    }
    if (context.strikerId == context.nonStrikerId) {
      throw ArgumentError('Striker and non-striker must be different players.');
    }
    if (context.ballsPerOver <= 0) {
      throw ArgumentError.value(context.ballsPerOver, 'ballsPerOver');
    }
    if (context.completedRuns < 0) {
      throw ArgumentError.value(context.completedRuns, 'completedRuns');
    }

    var strikerId = context.strikerId;
    var nonStrikerId = context.nonStrikerId;

    // Completed runs move the batters between the ends. The no-ball/wide
    // penalty itself is not a completed run; callers provide completedRuns.
    if (context.completedRuns.isOdd) {
      final oldStriker = strikerId;
      strikerId = nonStrikerId;
      nonStrikerId = oldStriker;
    }

    // At the end of every completed over the batters change ends again.
    // This is deliberately independent of the run-based movement above.
    if (context.legalBallCompleted) {
      final oldStriker = strikerId;
      strikerId = nonStrikerId;
      nonStrikerId = oldStriker;
    }

    return StrikeResult(
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      overCompleted: context.legalBallCompleted,
    );
  }
}
