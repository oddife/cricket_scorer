import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/scoring/enums/run_out_end.dart';
import 'package:cricket_scorer/domain/scoring/models/run_out_resolution.dart';

void main() {
  const resolver = RunOutResolver();

  test('zero completed runs: striker end contains striker', () {
    final result = resolver.resolve(
      strikerId: 10,
      nonStrikerId: 11,
      runOutEnd: RunOutEnd.striker,
      completedRuns: 0,
      crossedBeforeWicket: false,
    );

    expect(result.dismissedPlayerId, 10);
    expect(result.remainingBatterId, 11);
  });

  test('one completed run swaps the batters before the next run', () {
    final result = resolver.resolve(
      strikerId: 10,
      nonStrikerId: 11,
      runOutEnd: RunOutEnd.striker,
      completedRuns: 1,
      crossedBeforeWicket: false,
    );

    expect(result.dismissedPlayerId, 11);
    expect(result.remainingBatterId, 10);
  });

  test('crossing before wicket changes the end occupied at the incident', () {
    final result = resolver.resolve(
      strikerId: 10,
      nonStrikerId: 11,
      runOutEnd: RunOutEnd.striker,
      completedRuns: 0,
      crossedBeforeWicket: true,
    );

    expect(result.dismissedPlayerId, 11);
    expect(result.remainingBatterId, 10);
  });
}
