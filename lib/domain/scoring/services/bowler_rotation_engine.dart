import '../models/bowler_rotation_context.dart';
import '../models/bowler_rotation_result.dart';

class BowlerRotationEngine {
  const BowlerRotationEngine();

  BowlerRotationResult apply(BowlerRotationContext context) {
    _validate(context);

    if (!context.isLegalBall) {
      return BowlerRotationResult(
        currentBowlerId: context.currentBowlerId,
        completedOver: false,
        legalBallsInCurrentOver: context.legalBallsInCurrentOver,
        twoBowlerBlockCompleted: false,
        requiresBowlerSelection: false,
      );
    }

    final legalBall = context.legalBallsInCurrentOver;
    final finalLegalBall = legalBall == context.ballsPerOver - 1;
    final isFinalOddOver = context.twoBowlerMode &&
        context.isFinalOver &&
        (context.completedOvers + 1).isOdd;

    // The final odd over is a single-bowler over. Check this before applying
    // two-bowler alternation so its first ball remains with the selected bowler.
    if (isFinalOddOver) {
      if (!finalLegalBall) {
        return BowlerRotationResult(
          currentBowlerId: context.currentBowlerId,
          completedOver: false,
          legalBallsInCurrentOver: legalBall + 1,
          twoBowlerBlockCompleted: false,
          requiresBowlerSelection: false,
        );
      }

      return BowlerRotationResult(
        currentBowlerId: 0,
        completedOver: true,
        legalBallsInCurrentOver: context.ballsPerOver,
        twoBowlerBlockCompleted: false,
        requiresBowlerSelection: true,
      );
    }

    if (!finalLegalBall) {
      if (!context.twoBowlerMode) {
        return BowlerRotationResult(
          currentBowlerId: context.currentBowlerId,
          completedOver: false,
          legalBallsInCurrentOver: legalBall + 1,
          twoBowlerBlockCompleted: false,
          requiresBowlerSelection: false,
        );
      }

      final other = _otherBowler(
        context.activeTwoBowlerIds,
        context.currentBowlerId,
      );

      return BowlerRotationResult(
        currentBowlerId: other,
        completedOver: false,
        legalBallsInCurrentOver: legalBall + 1,
        twoBowlerBlockCompleted: false,
        requiresBowlerSelection: false,
      );
    }

    // The final legal delivery completes the over. The returned count includes
    // the delivery just processed; the application layer resets it for the
    // next over.
    if (!context.twoBowlerMode) {
      return BowlerRotationResult(
        currentBowlerId: 0,
        completedOver: true,
        legalBallsInCurrentOver: context.ballsPerOver,
        twoBowlerBlockCompleted: false,
        requiresBowlerSelection: true,
      );
    }

    // After two complete overs, both bowlers in the active pair have delivered
    // one legal over. The engine deliberately does not guess the next pair.
    final completesTwoOverBlock = (context.completedOvers + 1).isEven;

    if (completesTwoOverBlock) {
      return BowlerRotationResult(
        currentBowlerId: 0,
        completedOver: true,
        legalBallsInCurrentOver: context.ballsPerOver,
        twoBowlerBlockCompleted: true,
        requiresBowlerSelection: true,
      );
    }

    // Continue the same pair into the second over. The other bowler starts it.
    final other = _otherBowler(
      context.activeTwoBowlerIds,
      context.currentBowlerId,
    );

    return BowlerRotationResult(
      currentBowlerId: other,
      completedOver: true,
      legalBallsInCurrentOver: context.ballsPerOver,
      twoBowlerBlockCompleted: false,
      requiresBowlerSelection: false,
    );
  }

  int _otherBowler(List<int> pair, int currentBowlerId) {
    if (pair.first == currentBowlerId) {
      return pair[1];
    }
    return pair.first;
  }

  void _validate(BowlerRotationContext context) {
    if (context.eligibleBowlerIds.isEmpty) {
      throw ArgumentError('At least one eligible bowler is required.');
    }
    if (context.currentBowlerId <= 0) {
      throw ArgumentError.value(context.currentBowlerId, 'currentBowlerId');
    }
    if (!context.eligibleBowlerIds.contains(context.currentBowlerId)) {
      throw ArgumentError('Current bowler must be eligible.');
    }
    if (context.ballsPerOver <= 0) {
      throw ArgumentError.value(context.ballsPerOver, 'ballsPerOver');
    }
    if (context.legalBallsInCurrentOver < 0 ||
        context.legalBallsInCurrentOver >= context.ballsPerOver) {
      throw ArgumentError.value(
        context.legalBallsInCurrentOver,
        'legalBallsInCurrentOver',
      );
    }
    if (context.completedOvers < 0) {
      throw ArgumentError.value(context.completedOvers, 'completedOvers');
    }
    if (context.twoBowlerMode) {
      if (context.activeTwoBowlerIds.length != 2) {
        throw ArgumentError(
          'Two-Bowler Mode requires exactly two active bowlers.',
        );
      }
      if (context.activeTwoBowlerIds.toSet().length != 2) {
        throw ArgumentError(
          'The active two-bowler pair must contain two players.',
        );
      }
      for (final bowlerId in context.activeTwoBowlerIds) {
        if (!context.eligibleBowlerIds.contains(bowlerId)) {
          throw ArgumentError('Active bowlers must be eligible.');
        }
      }
    }
    if (context.isFinalOver && context.totalOvers <= 0) {
      throw ArgumentError.value(context.totalOvers, 'totalOvers');
    }
  }
}
