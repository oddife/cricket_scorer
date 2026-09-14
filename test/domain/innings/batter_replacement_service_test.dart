import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/innings/services/batter_replacement_service.dart';

void main() {
  const service = BatterReplacementService();

  test('returns only playing batters who have not batted', () {
    final result = service.eligibleBatters(
      playingBatterIds: [10, 11, 12, 13, 14],
      battedPlayerIds: {10, 12},
      strikerId: 10,
      nonStrikerId: 11,
    );

    expect(result, [13, 14]);
  });

  test('does not offer current batters as replacements', () {
    final result = service.eligibleBatters(
      playingBatterIds: [10, 11, 12],
      battedPlayerIds: {10},
      strikerId: 10,
      nonStrikerId: 11,
    );

    expect(result, [12]);
  });

  test('rejects a batter who has already batted', () {
    expect(
      () => service.validateSelection(
        replacementBatterId: 12,
        playingBatterIds: [10, 11, 12],
        battedPlayerIds: {10, 12},
        strikerId: 10,
        nonStrikerId: 11,
      ),
      throwsArgumentError,
    );
  });

  test('rejects a player outside the playing XI', () {
    expect(
      () => service.validateSelection(
        replacementBatterId: 99,
        playingBatterIds: [10, 11, 12],
        battedPlayerIds: {10},
        strikerId: 10,
        nonStrikerId: 11,
      ),
      throwsArgumentError,
    );
  });
}
