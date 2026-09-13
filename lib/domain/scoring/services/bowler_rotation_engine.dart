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

    if (!context.twoBowlerMode) {
      return BowlerRotationResult(
        currentBowlerId: 0,
        completedOver: true,
        legalBallsInCurrentOver: context.ballsPerOver,
        twoBowlerBlockCompleted: false,
        requiresBowlerSelection: true,
      );
    }

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
      final isFinalOddOver =
          context.isFinalOver && (context.completedOvers + 1).isOdd;
      final requiredPairSize = isFinalOddOver ? 1 : 2;
      if (context.activeTwoBowlerIds.length != requiredPairSize) {
        throw ArgumentError(
          isFinalOddOver
              ? 'The final odd over requires exactly one selected bowler.'
              : 'Two-Bowler Mode requires exactly two active bowlers.',
        );
      }
      if (context.activeTwoBowlerIds.toSet().length != requiredPairSize) {
        throw ArgumentError('Active bowlers must be unique.');
      }
      for (final bowlerId in context.activeTwoBowlerIds) {
        if (!context.eligibleBowlerIds.contains(bowlerId)) {
          throw ArgumentError('Active bowlers must be eligible.');
        }
      }
      if (isFinalOddOver &&
          context.activeTwoBowlerIds.single != context.currentBowlerId) {
        throw ArgumentError('The selected final-over bowler must be current.');
      }
    }
    if (context.isFinalOver && context.totalOvers <= 0) {
      throw ArgumentError.value(context.totalOvers, 'totalOvers');
    }
  }
}
