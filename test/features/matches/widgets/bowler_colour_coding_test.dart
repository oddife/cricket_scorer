import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/features/matches/widgets/bowler_colour_coding.dart';

void main() {
  group('BowlerColourCoding', () {
    test('keeps a player colour stable throughout the same match', () {
      final first = BowlerColourCoding.colorForBowler(
        matchId: 24,
        playerId: 105,
      );
      final afterPairChange = BowlerColourCoding.colorForBowler(
        matchId: 24,
        playerId: 105,
      );

      expect(afterPairChange, first);
    });

    test('assigns different colours to different bowlers in a match', () {
      final first = BowlerColourCoding.colorForBowler(
        matchId: 24,
        playerId: 105,
      );
      final second = BowlerColourCoding.colorForBowler(
        matchId: 24,
        playerId: 106,
      );

      expect(second, isNot(first));
    });

    test('uses a match-specific colour for the same player', () {
      final firstMatch = BowlerColourCoding.colorForBowler(
        matchId: 24,
        playerId: 105,
      );
      final secondMatch = BowlerColourCoding.colorForBowler(
        matchId: 25,
        playerId: 105,
      );

      expect(secondMatch, isNot(firstMatch));
    });
  });
}
