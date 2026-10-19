import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/scoring/models/bowler_rotation_context.dart';
import 'package:cricket_scorer/domain/scoring/services/bowler_rotation_engine.dart';

void main() {
  const engine = BowlerRotationEngine();

  BowlerRotationContext context({
    required int current,
    required int legalBalls,
    required int completedOvers,
    required int totalOvers,
    bool finalOver = false,
    List<int> pair = const [1, 2],
  }) {
    return BowlerRotationContext(
      currentBowlerId: current,
      legalBallsInCurrentOver: legalBalls,
      completedOvers: completedOvers,
      totalOvers: totalOvers,
      ballsPerOver: 6,
      isLegalBall: true,
      isFinalOver: finalOver,
      twoBowlerMode: true,
      activeTwoBowlerIds: pair,
      eligibleBowlerIds: const [1, 2, 3, 4, 5],
    );
  }

  test('three overs use a single bowler for the final odd over', () {
    final midOver = engine.apply(
      context(
        current: 1,
        legalBalls: 4,
        completedOvers: 2,
        totalOvers: 3,
        finalOver: true,
        pair: const [1],
      ),
    );
    expect(midOver.currentBowlerId, 1);
    expect(midOver.legalBallsInCurrentOver, 5);

    final end = engine.apply(
      context(
        current: 1,
        legalBalls: 5,
        completedOvers: 2,
        totalOvers: 3,
        finalOver: true,
        pair: const [1],
      ),
    );
    expect(end.completedOver, isTrue);
    expect(end.requiresBowlerSelection, isFalse);
  });

  test('five overs use two complete blocks then one single over', () {
    final blockEnd = engine.apply(
      context(current: 2, legalBalls: 5, completedOvers: 3, totalOvers: 5),
    );
    expect(blockEnd.twoBowlerBlockCompleted, isTrue);

    final finalOver = engine.apply(
      context(
        current: 1,
        legalBalls: 5,
        completedOvers: 4,
        totalOvers: 5,
        finalOver: true,
        pair: const [1],
      ),
    );
    expect(finalOver.completedOver, isTrue);
    expect(finalOver.requiresBowlerSelection, isFalse);
  });
}
