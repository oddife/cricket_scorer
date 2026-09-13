import '../models/bowler_rotation_context.dart';
import '../models/bowler_rotation_result.dart';

class BowlerRotationEngine {
  const BowlerRotationEngine();

  BowlerRotationResult apply(BowlerRotationContext context) {
    _validate(context);

    final legalBall = context.legalBallsInCurrentOver;

    // A delivery is not a rotation point until it is legal.
    if (legalBall < context.ballsPerOver - 1) {
      if (!context.twoBowlerMode) {
        return BowlerRotationResult(
          currentBowlerId: context.currentBowlerId,
          completedOver: false,
          legalBallsInCurrentOver: legalBall + 1,
          twoBowlerBlockCompleted: false,
        );
      }

      final pair = context.activeTwoBowlerIds;
      final other = pair.first == context.currentBowlerId
          ? pair[1]
          : pair.first;

      return BowlerRotationResult(
        currentBowlerId: other,
        completedOver: false,
        legalBallsInCurrentOver: legalBall + 1,
        twoBowlerBlockCompleted: false,
      );
    }

    // The final legal delivery completes the over.
    if (!context.twoBowlerMode) {
      return const BowlerRotationResult(
        currentBowlerId: 0,
        completedOver: true,
        legalBallsInCurrentOver: 0,
        twoBowlerBlockCompleted: false,
        requiresBowlerSelection: true,
      );
    }

    final isOddOver = (context.completedOvers + 1).isOdd;

    // An odd final over is a normal single-bowler over. No two-bowler block
    // is completed here, so the scorer selects the next bowler normally.
    if (isOddOver && context.isFinalOver) {
      return const BowlerRotationResult(
        currentBowlerId: 0,
        completedOver: true,
        legalBallsInCurrentOver: 0,
        twoBowlerBlockCompleted: false,
        requiresBowlerSelection: true,
      );
    }

    // After two complete overs, the pair has each delivered one legal over.
    // The engine deliberately does not guess the next pair.
    final completesTwoOverBlock = (context.completedOvers + 1).isEven;

    if (completesTwoOverBlock) {
      return const BowlerRotationResult(
        currentBowlerId: 0,
        completedOver: true,
        legalBallsInCurrentOver: 0,
        twoBowlerBlockCompleted: true,
        requiresBowlerSelection: true,
      );
    }

    // Continue the same pair into the second over. The other bowler starts it.
    final pair = context.activeTwoBowlerIds;
    final other = pair.first == context.currentBowlerId
        ? pair[1]
        : pair.first;

    return BowlerRotationResult(
      currentBowlerId: other,
      completedOver: true,
      legalBallsInCurrentOver: 0,
      twoBowlerBlockCompleted: false,
    );
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
    if (context.activeTwoBowlerIds.length != 2) {
      throw ArgumentError(
        'Two-Bowler Mode requires exactly two active bowlers.',
      );
    }
    if (context.activeTwoBowlerIds.toSet().length != 2) {
      throw ArgumentError('The active two-bowler pair must contain two players.');
    }
    for (final bowlerId in context.activeTwoBowlerIds) {
      if (!context.eligibleBowlerIds.contains(bowlerId)) {
        throw ArgumentError('Active bowlers must be eligible.');
      }
    }
    if (context.isFinalOver && context.totalOvers <= 0) {
      throw ArgumentError.value(context.totalOvers, 'totalOvers');
    }
  }
}
