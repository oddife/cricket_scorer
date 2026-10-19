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
