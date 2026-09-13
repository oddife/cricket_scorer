import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_scorer/domain/scoring/models/bowler_rotation_context.dart';
import 'package:cricket_scorer/domain/scoring/services/bowler_rotation_engine.dart';

void main() {
  const engine = BowlerRotationEngine();

  BowlerRotationContext context({
    int current = 1,
    int legalBalls = 0,
    int completedOvers = 0,
    bool legal = true,
    bool twoBowler = true,
    List<int> pair = const [1, 2],
    int totalOvers = 4,
    bool finalOver = false,
  }) {
    return BowlerRotationContext(
      eligibleBowlerIds: const [1, 2, 3, 4],
      currentBowlerId: current,
      legalBallsInCurrentOver: legalBalls,
      ballsPerOver: 6,
      twoBowlerMode: twoBowler,
      completedOvers: completedOvers,
      isLegalBall: legal,
      activeTwoBowlerIds: pair,
      totalOvers: totalOvers,
      isFinalOver: finalOver,
    );
  }

  test('2-Bowler Mode alternates every legal delivery', () {
    var current = 1;
    for (var ball = 0; ball < 6; ball++) {
      final result = engine.apply(context(current: current, legalBalls: ball));
      expect(result.legalBallsInCurrentOver, ball + 1);
      if (ball < 5) {
        current = result.currentBowlerId;
      }
    }
    expect(current, 2);
  });

  test('wide does not advance legal ball or bowler rotation', () {
    final result = engine.apply(context(legal: false));
    expect(result.currentBowlerId, 1);
    expect(result.legalBallsInCurrentOver, 0);
    expect(result.requiresBowlerSelection, isFalse);
  });

  test('no-ball does not advance legal ball or bowler rotation', () {
    final result = engine.apply(context(current: 2, legal: false));
    expect(result.currentBowlerId, 2);
    expect(result.legalBallsInCurrentOver, 0);
  });

  test('first over continues with the other bowler in the same pair', () {
    final result = engine.apply(
      context(current: 2, legalBalls: 5, completedOvers: 0),
    );
    expect(result.completedOver, isTrue);
    expect(result.currentBowlerId, 1);
    expect(result.twoBowlerBlockCompleted, isFalse);
    expect(result.requiresBowlerSelection, isFalse);
  });

  test('second over completes the two-bowler block', () {
    final result = engine.apply(
      context(current: 2, legalBalls: 5, completedOvers: 1),
    );
    expect(result.completedOver, isTrue);
    expect(result.twoBowlerBlockCompleted, isTrue);
    expect(result.requiresBowlerSelection, isTrue);
    expect(result.currentBowlerId, 0);
  });

  test('three overs use a single bowler for the final odd over', () {
    final result = engine.apply(
      context(
        current: 1,
        legalBalls: 0,
        completedOvers: 2,
        totalOvers: 3,
        finalOver: true,
      ),
    );
    expect(result.currentBowlerId, 1);
    expect(result.legalBallsInCurrentOver, 1);

    final midOver = engine.apply(
      context(
        current: 1,
        legalBalls: 4,
        completedOvers: 2,
        totalOvers: 3,
        finalOver: true,
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
      ),
    );
    expect(end.completedOver, isTrue);
    expect(end.requiresBowlerSelection, isTrue);
  });

  test('five overs use two complete blocks then one single over', () {
    final blockEnd = engine.apply(
      context(current: 2, legalBalls: 5, completedOvers: 3, totalOvers: 5),
    );
    expect(blockEnd.twoBowlerBlockCompleted, isTrue);

    final finalOver = engine.apply(
      context(
        current: 3,
        legalBalls: 0,
        completedOvers: 4,
        totalOvers: 5,
        finalOver: true,
        pair: const [3, 4],
      ),
    );
    expect(finalOver.currentBowlerId, 3);
    expect(finalOver.requiresBowlerSelection, isFalse);
  });

  test('normal mode keeps the same bowler until over end', () {
    final result = engine.apply(
      context(
        current: 3,
        legalBalls: 2,
        twoBowler: false,
        pair: const [],
      ),
    );
    expect(result.currentBowlerId, 3);
    expect(result.legalBallsInCurrentOver, 3);
    expect(result.completedOver, isFalse);
  });

  test('normal mode requests a bowler after over completion', () {
    final result = engine.apply(
      context(
        current: 3,
        legalBalls: 5,
        twoBowler: false,
        pair: const [],
      ),
    );
    expect(result.completedOver, isTrue);
    expect(result.requiresBowlerSelection, isTrue);
  });

  test('rejects an invalid current bowler', () {
    expect(
      () => engine.apply(context(current: 99)),
      throwsArgumentError,
    );
  });

  test('rejects an invalid active pair', () {
    expect(
      () => engine.apply(context(pair: const [1, 1])),
      throwsArgumentError,
    );
  });
}
