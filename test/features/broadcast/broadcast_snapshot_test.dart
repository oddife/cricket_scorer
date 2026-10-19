import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/features/broadcast/models/broadcast_snapshot.dart';

void main() {
  group('BroadcastSnapshot', () {
    test('formats overs from legal balls and serializes display state', () {
      final capturedAt = DateTime.utc(2026, 10, 20, 12);
      final snapshot = BroadcastSnapshot(
        ready: true,
        matchId: 'match-sync-id',
        matchName: 'Sunday Final',
        teamAName: 'Kings',
        teamBName: 'Warriors',
        battingTeamName: 'Kings',
        bowlingTeamName: 'Warriors',
        inningsNumber: 2,
        runs: 124,
        wickets: 4,
        totalLegalBalls: 77,
        target: 150,
        runsRequired: 26,
        ballsRemaining: 43,
        runRate: 9.66,
        requiredRunRate: 3.63,
        matchStatus: 'inProgress',
        scoringSource: BroadcastScoringSource.androidSync,
        capturedAt: capturedAt,
        lastSyncAt: capturedAt.subtract(const Duration(seconds: 2)),
        batters: const [
          BroadcastBatterLine(
            name: 'Audrin',
            runs: 48,
            balls: 32,
            fours: 5,
            sixes: 1,
            isOnStrike: true,
          ),
        ],
        bowler: const BroadcastBowlerLine(
          name: 'Mario',
          legalBallsBowled: 21,
          runsConceded: 24,
          wickets: 2,
        ),
        currentOver: const [
          BroadcastDelivery(
            label: '1',
            totalRuns: 1,
            isWicket: false,
            isLegalBall: true,
          ),
          BroadcastDelivery(
            label: 'W',
            totalRuns: 0,
            isWicket: true,
            isLegalBall: true,
          ),
        ],
      );

      expect(snapshot.oversText, '12.5');
      final json = snapshot.toJson();
      expect(json['ready'], isTrue);
      expect(json['oversText'], '12.5');
      expect(json['scoringSource'], 'android_sync');
      expect(json['capturedAt'], capturedAt.toIso8601String());
      expect((json['batters'] as List).single['isOnStrike'], isTrue);
      expect(json['bowler'], isA<Map<String, Object?>>());
      expect((json['currentOver'] as List).length, 2);
    });

    test('rejects invalid balls-per-over values', () {
      expect(
        () => BroadcastSnapshot(
          capturedAt: DateTime.utc(2026),
          ballsPerOver: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
