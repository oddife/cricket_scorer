import 'broadcast_full_screen_geometry.dart';

/// Presentation-only settings for the full-screen broadcast scorecard.
///
/// This model intentionally contains no scoring, match, sync, or database
/// behavior. It is safe to persist as part of the broadcast workspace.
class BroadcastFullScreenSettings {
  static const viewNames = <String>[
    'combined',
    'batting',
    'bowling',
    'playingXi',
  ];

  const BroadcastFullScreenSettings({
    this.enabled = false,
    this.view = 'combined',
    this.style = 'traditional',
    this.transparent = false,
    this.showCompactScorecard = false,
    this.playingXiMode = 'both',
    this.playingXiTeam = 'teamA',
    double opacity = 100,
    this.viewOpacities,
    this.geometries = const {
      'combined': BroadcastFullScreenGeometry.full,
      'batting': BroadcastFullScreenGeometry.full,
      'bowling': BroadcastFullScreenGeometry.full,
      'playingXi': BroadcastFullScreenGeometry.full,
    },
  }) : _fallbackOpacity = opacity;

  final bool enabled;
  final String view;
  final String style;
  final bool transparent;
  final bool showCompactScorecard;
  final String playingXiMode;
  final String playingXiTeam;

  /// Legacy preference fallback; new preferences keep a value for each view.
  final double _fallbackOpacity;
  final Map<String, double>? viewOpacities;
  final Map<String, BroadcastFullScreenGeometry> geometries;

  double opacityFor(String targetView) =>
      viewOpacities?[targetView] ?? _fallbackOpacity;

  /// Backwards-compatible opacity for the selected full-screen view.
  double get opacity => opacityFor(view);

  Map<String, double> get effectiveViewOpacities => {
        for (final targetView in viewNames)
          targetView: opacityFor(targetView),
      };

  BroadcastFullScreenGeometry geometryFor(String targetView) =>
      geometries[targetView] ?? BroadcastFullScreenGeometry.full;

  bool get isValid {
    const requiredViews = {'combined', 'batting', 'bowling', 'playingXi'};
    final savedOpacities = viewOpacities;
    if (savedOpacities != null &&
        (savedOpacities.length != requiredViews.length ||
            !savedOpacities.keys.toSet().containsAll(requiredViews))) {
      return false;
    }
    for (final targetView in requiredViews) {
      final value = opacityFor(targetView);
      if (!value.isFinite || value < 10 || value > 100) return false;
    }

    if (geometries.length != requiredViews.length ||
        !geometries.keys.toSet().containsAll(requiredViews)) {
      return false;
    }
    if (!requiredViews.contains(view)) return false;
    if (!const {'traditional', 'tvBroadcast'}.contains(style)) return false;
    if (playingXiMode != 'both' && playingXiMode != 'single') return false;
    if (playingXiTeam != 'teamA' && playingXiTeam != 'teamB') return false;
    return geometries.values.every((geometry) => geometry.isValid);
  }

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'view': view,
        'style': style,
        'transparent': transparent,
        'showCompactScorecard': showCompactScorecard,
        'playingXiMode': playingXiMode,
        'playingXiTeam': playingXiTeam,
        // Keep the legacy active-view field for old readers.
        'opacity': opacity,
        'viewOpacities': effectiveViewOpacities,
        'viewGeometries': {
          for (final entry in geometries.entries) entry.key: entry.value.toJson(),
        },
      };

  factory BroadcastFullScreenSettings.fromJson(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Full-screen settings must be an object.');
    }

    final geometryRaw = raw['viewGeometries'];
    if (geometryRaw is! Map) {
      throw const FormatException('Full-screen settings require viewGeometries.');
    }

    final geometries = <String, BroadcastFullScreenGeometry>{};
    for (final targetView in viewNames) {
      geometries[targetView] =
          BroadcastFullScreenGeometry.fromJson(geometryRaw[targetView]);
    }

    Map<String, double>? parsedViewOpacities;
    final opacityRaw = raw['viewOpacities'];
    if (opacityRaw != null && opacityRaw is! Map) {
      throw const FormatException('Full-screen viewOpacities must be an object.');
    }
    if (opacityRaw is Map) {
      if (opacityRaw.length != viewNames.length ||
          opacityRaw.keys.any(
            (key) => key is! String || !viewNames.contains(key),
          )) {
        throw const FormatException(
          'Full-screen viewOpacities must contain exactly the four views.',
        );
      }
      parsedViewOpacities = <String, double>{};
      for (final targetView in viewNames) {
        final value = opacityRaw[targetView];
        if (value is! num) {
          throw FormatException(
            'Full-screen opacity for $targetView must be numeric.',
          );
        }
        parsedViewOpacities[targetView] = value.toDouble();
      }
    }

    final settings = BroadcastFullScreenSettings(
      enabled: raw['enabled'] is bool ? raw['enabled'] as bool : false,
      view: raw['view'] is String ? raw['view'] as String : 'combined',
      style: raw['style'] is String ? raw['style'] as String : 'traditional',
      transparent:
          raw['transparent'] is bool ? raw['transparent'] as bool : false,
      showCompactScorecard: raw['showCompactScorecard'] is bool
          ? raw['showCompactScorecard'] as bool
          : false,
      playingXiMode:
          raw['playingXiMode'] is String ? raw['playingXiMode'] as String : 'both',
      playingXiTeam:
          raw['playingXiTeam'] is String ? raw['playingXiTeam'] as String : 'teamA',
      opacity: raw['opacity'] is num ? (raw['opacity'] as num).toDouble() : 100,
      viewOpacities: parsedViewOpacities,
      geometries: geometries,
    );
    if (!settings.isValid) {
      throw const FormatException('Invalid full-screen settings.');
    }
    return settings;
  }

  BroadcastFullScreenSettings copyWith({
    bool? enabled,
    String? view,
    String? style,
    bool? transparent,
    bool? showCompactScorecard,
    String? playingXiMode,
    String? playingXiTeam,
    double? opacity,
    Map<String, double>? viewOpacities,
    Map<String, BroadcastFullScreenGeometry>? geometries,
  }) {
    final nextView = view ?? this.view;
    final nextViewOpacities =
        Map<String, double>.from(viewOpacities ?? effectiveViewOpacities);
    if (opacity != null) nextViewOpacities[nextView] = opacity;

    return BroadcastFullScreenSettings(
      enabled: enabled ?? this.enabled,
      view: nextView,
      style: style ?? this.style,
      transparent: transparent ?? this.transparent,
      showCompactScorecard:
          showCompactScorecard ?? this.showCompactScorecard,
      playingXiMode: playingXiMode ?? this.playingXiMode,
      playingXiTeam: playingXiTeam ?? this.playingXiTeam,
      opacity: _fallbackOpacity,
      viewOpacities: nextViewOpacities,
      geometries: geometries ?? this.geometries,
    );
  }
}
