import 'broadcast_full_screen_geometry.dart';

/// Presentation-only settings for the full-screen broadcast scorecard.
///
/// This model intentionally contains no scoring, match, sync, or database
/// behavior. It is safe to persist as part of the broadcast workspace.
class BroadcastFullScreenSettings {
  const BroadcastFullScreenSettings({
    this.enabled = false,
    this.view = 'combined',
    this.style = 'traditional',
    this.transparent = false,
    this.showCompactScorecard = false,
    this.playingXiMode = 'both',
    this.playingXiTeam = 'teamA',
    this.opacity = 100,
    this.geometries = const {
      'combined': BroadcastFullScreenGeometry.full,
      'batting': BroadcastFullScreenGeometry.full,
      'bowling': BroadcastFullScreenGeometry.full,
      'playingXi': BroadcastFullScreenGeometry.full,
    },
  });

  final bool enabled;
  final String view;
  final String style;
  final bool transparent;
  final bool showCompactScorecard;
  final String playingXiMode;
  final String playingXiTeam;
  final double opacity;
  final Map<String, BroadcastFullScreenGeometry> geometries;

  BroadcastFullScreenGeometry geometryFor(String view) =>
      geometries[view] ?? BroadcastFullScreenGeometry.full;

  bool get isValid {
    if (opacity.isNaN || opacity.isInfinite || opacity < 10 || opacity > 100) {
      return false;
    }
    const requiredViews = {'combined', 'batting', 'bowling', 'playingXi'};
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
        'opacity': opacity,
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

    const views = ['combined', 'batting', 'bowling', 'playingXi'];
    final geometries = <String, BroadcastFullScreenGeometry>{};
    for (final view in views) {
      geometries[view] = BroadcastFullScreenGeometry.fromJson(geometryRaw[view]);
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
    Map<String, BroadcastFullScreenGeometry>? geometries,
  }) =>
      BroadcastFullScreenSettings(
        enabled: enabled ?? this.enabled,
        view: view ?? this.view,
        style: style ?? this.style,
        transparent: transparent ?? this.transparent,
        showCompactScorecard:
            showCompactScorecard ?? this.showCompactScorecard,
        playingXiMode: playingXiMode ?? this.playingXiMode,
        playingXiTeam: playingXiTeam ?? this.playingXiTeam,
        opacity: opacity ?? this.opacity,
        geometries: geometries ?? this.geometries,
      );
}
