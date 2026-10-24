import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/features/broadcast/models/broadcast_full_screen_geometry.dart';

void main() {
  group('BroadcastFullScreenGeometry', () {
    test('accepts a full canvas', () {
      expect(BroadcastFullScreenGeometry.full.isValid, isTrue);
    });

    test('accepts a normalized partial rectangle', () {
      const geometry = BroadcastFullScreenGeometry(
        x: 5,
        y: 10,
        width: 80,
        height: 70,
      );

      expect(geometry.isValid, isTrue);
      expect(geometry.toJson(), {
        'x': 5.0,
        'y': 10.0,
        'width': 80.0,
        'height': 70.0,
      });
    });

    test('rejects rectangles outside the canvas', () {
      const geometry = BroadcastFullScreenGeometry(
        x: 95,
        y: 0,
        width: 10,
        height: 100,
      );

      expect(geometry.isValid, isFalse);
    });

    test('rejects non-positive dimensions', () {
      expect(
        const BroadcastFullScreenGeometry(
          x: 0,
          y: 0,
          width: 0,
          height: 100,
        ).isValid,
        isFalse,
      );
    });

    test('round-trips JSON', () {
      const original = BroadcastFullScreenGeometry(
        x: 7,
        y: 12,
        width: 76,
        height: 64,
      );

      final restored =
          BroadcastFullScreenGeometry.fromJson(original.toJson());

      expect(restored.x, original.x);
      expect(restored.y, original.y);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
    });

    test('throws for malformed JSON', () {
      expect(
        () => BroadcastFullScreenGeometry.fromJson({'x': 0}),
        throwsFormatException,
      );
    });
  });
}
