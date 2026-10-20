import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/features/broadcast/models/broadcast_snapshot.dart';
import 'package:cricket_scorer/features/broadcast/state/broadcast_state_coordinator.dart';

void main() {
  group('BroadcastStateCoordinator', () {
    late BroadcastStateCoordinator coordinator;

    setUp(() => coordinator = BroadcastStateCoordinator());
    tearDown(() => coordinator.dispose());

    test('keeps snapshot, visibility and messages in one state document', () {
      final now = DateTime.now();
      coordinator.updateSnapshot(
        BroadcastSnapshot(
          ready: true,
          matchName: 'Sunday Final',
          runs: 124,
          wickets: 4,
          totalLegalBalls: 77,
          capturedAt: now,
        ),
      );
      coordinator.setOverlayEnabled(BroadcastOverlay.scorecard, true);
      coordinator.setOverlayEnabled(BroadcastOverlay.ticker, true);
      coordinator.showTicker(
        'Thanks to our sponsor',
        duration: const Duration(seconds: 20),
      );
      coordinator.triggerEvent(
        kind: 'SIX',
        detail: 'Audrin clears the boundary',
        duration: const Duration(seconds: 5),
      );

      final json = coordinator.toJson();
      expect(json['version'], 1);
      expect(
        (json['snapshot'] as Map<String, Object?>)['matchName'],
        'Sunday Final',
      );
      expect(
        (json['overlays'] as Map<String, Object?>)['scorecard'],
        isTrue,
      );
      expect(
        (json['overlays'] as Map<String, Object?>)['lowerThird'],
        isFalse,
      );
      expect(
        (json['ticker'] as Map<String, Object?>)['title'],
        'Thanks to our sponsor',
      );
      expect(
        (json['event'] as Map<String, Object?>)['title'],
        'SIX',
      );
      expect(
        (json['event'] as Map<String, Object?>)['detail'],
        'Audrin clears the boundary',
      );
    });

    test('selects and serializes scorecard display styles', () {
      expect(
        coordinator.scorecardStyle,
        BroadcastScorecardStyle.fullBroadcastBar,
      );
      expect(coordinator.toJson()['scorecardStyle'], 'fullBroadcastBar');

      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      expect(coordinator.toJson()['scorecardStyle'], 'minimal');

      coordinator.setScorecardStyle(BroadcastScorecardStyle.detailed);
      expect(coordinator.toJson()['scorecardStyle'], 'detailed');
    });

    test('remembers independent geometry for each scorecard style', () {
      coordinator.setLayout({
        'scorecard': {'x': 4, 'y': 81, 'width': 90, 'height': 9},
      });

      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      expect(coordinator.layout['scorecard'], {
        'x': 3.0,
        'y': 82.5,
        'width': 94.0,
        'height': 8.0,
      });
      coordinator.setLayout({
        'scorecard': {'x': 5, 'y': 84, 'width': 90, 'height': 6},
      });

      coordinator.setScorecardStyle(BroadcastScorecardStyle.detailed);
      expect(coordinator.layout['scorecard']!['height'], 8.0);
      coordinator.setLayout({
        'scorecard': {'x': 10, 'y': 80, 'width': 85, 'height': 10},
      });

      coordinator.setScorecardStyle(BroadcastScorecardStyle.fullBroadcastBar);
      expect(coordinator.layout['scorecard'], {
        'x': 4.0,
        'y': 81.0,
        'width': 90.0,
        'height': 9.0,
      });
      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      expect(coordinator.layout['scorecard'], {
        'x': 5.0,
        'y': 84.0,
        'width': 90.0,
        'height': 6.0,
      });
      final json = coordinator.toJson();
      expect(
        (json['scorecardGeometries'] as Map<String, dynamic>)['minimal'],
        {'x': 5.0, 'y': 84.0, 'width': 90.0, 'height': 6.0},
      );
    });

    test('restores saved scorecard geometry map', () {
      coordinator.setScorecardGeometries({
        BroadcastScorecardStyle.minimal: {
          'x': 7,
          'y': 85,
          'width': 88,
          'height': 5,
        },
      });
      coordinator.setScorecardStyle(BroadcastScorecardStyle.minimal);
      expect(coordinator.layout['scorecard'], {
        'x': 7.0,
        'y': 85.0,
        'width': 88.0,
        'height': 5.0,
      });
    });

    test('rejects invalid saved scorecard geometry', () {
      expect(
        () => coordinator.setScorecardGeometries({
          BroadcastScorecardStyle.minimal: {
            'x': 90,
            'y': 90,
            'width': 20,
            'height': 8,
          },
        }),
        throwsArgumentError,
      );
    });

    test('stores broadcast layer geometry as percentages', () {
      coordinator.setLayout({
        'scorecard': {
          'x': 8.0,
          'y': 6.0,
          'width': 55.0,
          'height': 28.0,
        },
      });

      final state = coordinator.toJson();
      final layout = state['layout'] as Map<String, Map<String, double>>;
      expect(layout['scorecard']!['x'], 8.0);
      expect(layout['scorecard']!['width'], 55.0);
      expect(layout['ticker']!['x'], 3.0);
    });

    test('defaults compact scorecard above ticker at the bottom', () {
      final layout = coordinator.layout;
      final scorecard = layout['scorecard']!;
      final ticker = layout['ticker']!;

      expect(scorecard['y'], greaterThan(50));
      expect(scorecard['y']! + scorecard['height']!, lessThan(ticker['y']!));
      expect(ticker['y']! + ticker['height']!, lessThanOrEqualTo(100));
      expect(scorecard['width'], 94);
      expect(scorecard['height'], 8);
      expect(scorecard['y'], 82.5);
      expect(ticker['width'], 94);
    });

    test('clearing messages does not alter score snapshot or visibility', () {
      final now = DateTime.now();
      coordinator.updateSnapshot(
        BroadcastSnapshot(
          ready: true,
          runs: 42,
          wickets: 1,
          capturedAt: now,
        ),
      );
      coordinator.setOverlayEnabled(BroadcastOverlay.scorecard, true);
      coordinator.showTicker('Temporary notice');
      coordinator.clearMessages();

      final json = coordinator.toJson();
      expect(
        (json['snapshot'] as Map<String, Object?>)['runs'],
        42,
      );
      expect(
        (json['overlays'] as Map<String, Object?>)['scorecard'],
        isTrue,
      );
      expect(json['ticker'], isNull);
      expect(json['event'], isNull);
    });

    test('temporary ticker expires without touching scoring snapshot', () async {
      final now = DateTime.now();
      coordinator.updateSnapshot(
        BroadcastSnapshot(
          ready: true,
          runs: 7,
          capturedAt: now,
        ),
      );
      coordinator.showTicker(
        'Short message',
        duration: const Duration(milliseconds: 25),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));

      final json = coordinator.toJson();
      expect(json['ticker'], isNull);
      expect(
        (json['snapshot'] as Map<String, Object?>)['runs'],
        7,
      );
    });
  });
}
