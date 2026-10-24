import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/features/broadcast/models/broadcast_full_screen_geometry.dart';
import 'package:cricket_scorer/features/broadcast/models/broadcast_full_screen_settings.dart';

void main() {
  group('BroadcastFullScreenSettings', () {
    test('defaults to a valid full-canvas combined view', () {
      const settings = BroadcastFullScreenSettings();

      expect(settings.isValid, isTrue);
      expect(settings.view, 'combined');
      expect(settings.opacity, 100);
      expect(settings.geometryFor('combined'), BroadcastFullScreenGeometry.full);
    });

    test('round-trips all presentation settings', () {
      const settings = BroadcastFullScreenSettings(
        enabled: true,
        view: 'batting',
        style: 'tvBroadcast',
        transparent: true,
        showCompactScorecard: true,
        playingXiMode: 'single',
        playingXiTeam: 'teamB',
        opacity: 75,
        geometries: {
          'combined': BroadcastFullScreenGeometry.full,
          'batting': BroadcastFullScreenGeometry(
            x: 5,
            y: 10,
            width: 80,
            height: 70,
          ),
          'bowling': BroadcastFullScreenGeometry.full,
          'playingXi': BroadcastFullScreenGeometry.full,
        },
      );

      final restored = BroadcastFullScreenSettings.fromJson(settings.toJson());

      expect(restored.toJson(), settings.toJson());
      expect(restored.isValid, isTrue);
    });

    test('rejects opacity outside the supported range', () {
      const settings = BroadcastFullScreenSettings(opacity: 101);
      expect(settings.isValid, isFalse);
    });

    test('rejects missing view geometry', () {
      expect(
        () => BroadcastFullScreenSettings.fromJson({
          'viewGeometries': {
            'combined': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
          },
        }),
        throwsFormatException,
      );
    });

    test('copyWith changes only requested presentation fields', () {
      const settings = BroadcastFullScreenSettings();
      final changed = settings.copyWith(opacity: 60, view: 'bowling');

      expect(changed.opacity, 60);
      expect(changed.view, 'bowling');
      expect(changed.style, settings.style);
      expect(changed.geometries, settings.geometries);
    });
  });
}
