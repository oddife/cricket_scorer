import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/scoring/models/strike_context.dart';
import 'package:cricket_scorer/domain/scoring/services/strike_engine.dart';

void main() {
  const engine = StrikeEngine();

  StrikeContext context({
    int completedRuns = 0,
    bool legalBallCompleted = false,
  }) {
    return StrikeContext(
      strikerId: 1,
      nonStrikerId: 2,
      legalBallCompleted: legalBallCompleted,
      ballsPerOver: 6,
      completedRuns: completedRuns,
    );
  }

  test('zero runs keeps strike', () {
    final result = engine.apply(context());
    expect(result.strikerId, 1);
    expect(result.nonStrikerId, 2);
    expect(result.overCompleted, isFalse);
  });

  test('one completed run changes strike', () {
    final result = engine.apply(context(completedRuns: 1));
    expect(result.strikerId, 2);
    expect(result.nonStrikerId, 1);
  });

  test('two completed runs keep strike', () {
    final result = engine.apply(context(completedRuns: 2));
    expect(result.strikerId, 1);
    expect(result.nonStrikerId, 2);
  });

  test('three completed runs change strike', () {
    final result = engine.apply(context(completedRuns: 3));
    expect(result.strikerId, 2);
    expect(result.nonStrikerId, 1);
  });

  test('four and six runs keep strike', () {
    final four = engine.apply(context(completedRuns: 4));
    final six = engine.apply(context(completedRuns: 6));

    expect(four.strikerId, 1);
    expect(four.nonStrikerId, 2);
    expect(six.strikerId, 1);
    expect(six.nonStrikerId, 2);
  });

  test('end of over changes strike after run movement', () {
    final result = engine.apply(
      context(completedRuns: 1, legalBallCompleted: true),
    );

    // One run swaps them, then the completed over swaps them again.
    expect(result.strikerId, 1);
    expect(result.nonStrikerId, 2);
    expect(result.overCompleted, isTrue);
  });

  test('end of over with even runs changes strike once', () {
    final result = engine.apply(
      context(completedRuns: 2, legalBallCompleted: true),
    );

    expect(result.strikerId, 2);
    expect(result.nonStrikerId, 1);
  });

  test('illegal delivery does not trigger an over change', () {
    final result = engine.apply(context(completedRuns: 1));
    expect(result.overCompleted, isFalse);
    expect(result.strikerId, 2);
  });

  test('rejects invalid player IDs', () {
    expect(
      () => engine.apply(
        const StrikeContext(
          strikerId: 1,
          nonStrikerId: 1,
          legalBallCompleted: false,
          ballsPerOver: 6,
          completedRuns: 0,
        ),
      ),
      throwsArgumentError,
    );
  });
}
