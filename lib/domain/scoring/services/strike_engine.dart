import '../models/strike_context.dart';
import '../models/strike_result.dart';

class StrikeEngine {
  const StrikeEngine();

  StrikeResult apply(StrikeContext context) {
    _validate(context);

    var strikerId = context.strikerId;
    var nonStrikerId = context.nonStrikerId;
    var swappedForRuns = false;
    var swappedAtEndOfOver = false;

    if (context.completedRuns.isOdd) {
      final temp = strikerId;
      strikerId = nonStrikerId;
      nonStrikerId = temp;
      swappedForRuns = true;
    }

    // An over-end swap is independent of run-based movement.
    // This also handles the case where an odd number of runs was completed
    // on the final ball: the two swaps cancel and the original striker faces
    // the first ball of the next over.
    if (context.isEndOfOver) {
      final temp = strikerId;
      strikerId = nonStrikerId;
      nonStrikerId = temp;
      swappedAtEndOfOver = true;
    }

    return StrikeResult(
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      swappedForRuns: swappedForRuns,
      swappedAtEndOfOver: swappedAtEndOfOver,
    );
  }

  void _validate(StrikeContext context) {
    if (context.strikerId <= 0) {
      throw ArgumentError.value(context.strikerId, 'strikerId');
    }
    if (context.nonStrikerId <= 0) {
      throw ArgumentError.value(context.nonStrikerId, 'nonStrikerId');
    }
    if (context.strikerId == context.nonStrikerId) {
      throw ArgumentError('Striker and non-striker must be different players.');
    }
    if (context.completedRuns < 0) {
      throw ArgumentError.value(context.completedRuns, 'completedRuns');
    }
  }
}
