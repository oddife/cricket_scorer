import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/features/matches/widgets/bowler_colour_coding.dart';

void main() {
  group('BowlerColourCoding', () {
    test('same shared player identity gives the same colour on every device', () {
      final android = BowlerColourCoding.colorForBowler(
        playerIdentity: 'player-sync-550e8400-e29b-41d4-a716-446655440000',
      );
      final docker = BowlerColourCoding.colorForBowler(
        playerIdentity: 'player-sync-550e8400-e29b-41d4-a716-446655440000',
      );

      expect(docker, android);
    });

    test('different players normally receive distinct colours', () {
      final first = BowlerColourCoding.colorForBowler(
        playerIdentity: 'player-sync-bowler-a',
      );
      final second = BowlerColourCoding.colorForBowler(
        playerIdentity: 'player-sync-bowler-b',
      );

      expect(second, isNot(first));
    });

    test('colour does not depend on match ID or local player ID', () {
      final firstDevice = BowlerColourCoding.colorForBowler(
        playerIdentity: 'shared-player-identity',
      );
      final secondDevice = BowlerColourCoding.colorForBowler(
        playerIdentity: 'shared-player-identity',
      );

      expect(secondDevice, firstDevice);
    });
  });
}
