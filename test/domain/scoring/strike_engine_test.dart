import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/scoring/models/strike_context.dart';
import 'package:cricket_scorer/domain/scoring/services/strike_engine.dart';

StrikeContext context({
  int runs = 0,
  bool legal = true,
  bool endOfOver = false,
}) {
  return StrikeContext(
    strikerId: 10,
    nonStrikerId: 20,
    completedRuns: runs,
    isLegalBall: legal,
    isEndOfOver: endOfOver,
  );
}

void main() {
  const engine = StrikeEngine();

  test('zero runs keeps strike', () {
    final result = engine.apply(context());
    expect(result.strikerId, 10);
    expect(result.nonStrikerId, 20);
    expect(result.swappedForRuns, isFalse);
  });

  test('one run swaps strike', () {
    final result = engine.apply(context(runs: 1));
    expect(result.strikerId, 20);
    expect(result.nonStrikerId, 10);
    expect(result.swappedForRuns, isTrue);
  });

  test('two runs keeps strike', () {
    final result = engine.apply(context(runs: 2));
    expect(result.strikerId, 10);
    expect(result.nonStrikerId, 20);
  });

  test('three runs swaps strike', () {
    final result = engine.apply(context(runs: 3));
    expect(result.strikerId, 20);
    expect(result.nonStrikerId, 10);
  });

  test('four runs keeps strike', () {
    final result = engine.apply(context(runs: 4));
    expect(result.strikerId, 10);
    expect(result.nonStrikerId, 20);
  });

  test('six runs keeps strike', () {
    final result = engine.apply(context(runs: 6));
    expect(result.strikerId, 10);
    expect(result.nonStrikerId, 20);
  });

  test('illegal delivery can still swap when completed runs are odd', () {
    final result = engine.apply(context(runs: 1, legal: false));
    expect(result.strikerId, 20);
    expect(result.nonStrikerId, 10);
  });

  test('even runs at end of over swaps strike', () {
    final result = engine.apply(context(runs: 2, endOfOver: true));
    expect(result.strikerId, 20);
    expect(result.nonStrikerId, 10);
    expect(result.swappedAtEndOfOver, isTrue);
  });

  test('odd runs at end of over cancel through two swaps', () {
    final result = engine.apply(context(runs: 1, endOfOver: true));
    expect(result.strikerId, 10);
    expect(result.nonStrikerId, 20);
    expect(result.swappedForRuns, isTrue);
    expect(result.swappedAtEndOfOver, isTrue);
  });

  test('rejects the same player at both ends', () {
    expect(
      () => engine.apply(
        const StrikeContext(
          strikerId: 10,
          nonStrikerId: 10,
          completedRuns: 0,
          isLegalBall: true,
          isEndOfOver: false,
        ),
      ),
      throwsArgumentError,
    );
  });
}
