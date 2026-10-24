/// Normalized geometry for one full-screen broadcast view.
///
/// All values are percentages of the output canvas. The model is presentation
/// only; it does not interact with scoring or sync state.
class BroadcastFullScreenGeometry {
  const BroadcastFullScreenGeometry({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  static const full = BroadcastFullScreenGeometry(
    x: 0,
    y: 0,
    width: 100,
    height: 100,
  );

  bool get isValid =>
      x.isFinite &&
      y.isFinite &&
      width.isFinite &&
      height.isFinite &&
      x >= 0 &&
      y >= 0 &&
      width > 0 &&
      height > 0 &&
      x + width <= 100 &&
      y + height <= 100;

  Map<String, double> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  factory BroadcastFullScreenGeometry.fromJson(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Full-screen geometry must be an object.');
    }

    double read(String key) {
      final value = raw[key];
      if (value is! num) {
        throw FormatException('Full-screen geometry $key must be numeric.');
      }
      return value.toDouble();
    }

    final geometry = BroadcastFullScreenGeometry(
      x: read('x'),
      y: read('y'),
      width: read('width'),
      height: read('height'),
    );
    if (!geometry.isValid) {
      throw const FormatException(
        'Full-screen geometry must stay inside the 0–100% canvas.',
      );
    }
    return geometry;
  }

  BroadcastFullScreenGeometry copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) =>
      BroadcastFullScreenGeometry(
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
      );
}
