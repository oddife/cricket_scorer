import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/broadcast_snapshot.dart';
import '../models/broadcast_full_screen_settings.dart';
import '../models/broadcast_full_screen_geometry.dart';

enum BroadcastOverlay {
  scorecard,
  ticker,
  lowerThird,
  lastBall,
}


enum BroadcastFullScreenView { combined, batting, bowling, playingXi }

extension BroadcastFullScreenViewJson on BroadcastFullScreenView {
  String get wireValue => switch (this) {
        BroadcastFullScreenView.combined => 'combined',
        BroadcastFullScreenView.batting => 'batting',
        BroadcastFullScreenView.bowling => 'bowling',
        BroadcastFullScreenView.playingXi => 'playingXi',
      };

  String get label => switch (this) {
        BroadcastFullScreenView.combined => 'Combined Batting & Bowling',
        BroadcastFullScreenView.batting => 'Batting',
        BroadcastFullScreenView.bowling => 'Bowling',
        BroadcastFullScreenView.playingXi => 'Playing XI',
      };

  static BroadcastFullScreenView? fromWireValue(String value) {
    for (final view in BroadcastFullScreenView.values) {
      if (view.wireValue == value) return view;
    }
    return null;
  }
}

enum BroadcastFullScreenStyle { traditional, tvBroadcast }

extension BroadcastFullScreenStyleJson on BroadcastFullScreenStyle {
  String get wireValue => switch (this) {
        BroadcastFullScreenStyle.traditional => 'traditional',
        BroadcastFullScreenStyle.tvBroadcast => 'tvBroadcast',
      };

  String get label => switch (this) {
        BroadcastFullScreenStyle.traditional => 'Traditional scorecard table',
        BroadcastFullScreenStyle.tvBroadcast => 'TV broadcast design',
      };

  static BroadcastFullScreenStyle? fromWireValue(String value) {
    for (final style in BroadcastFullScreenStyle.values) {
      if (style.wireValue == value) return style;
    }
    return null;
  }
}

enum BroadcastScorecardStyle { minimal, detailed, fullBroadcastBar }

extension BroadcastScorecardStyleJson on BroadcastScorecardStyle {
  String get wireValue => switch (this) {
        BroadcastScorecardStyle.minimal => 'minimal',
        BroadcastScorecardStyle.detailed => 'detailed',
        BroadcastScorecardStyle.fullBroadcastBar => 'fullBroadcastBar',
      };

  String get label => switch (this) {
        BroadcastScorecardStyle.minimal => 'Minimal',
        BroadcastScorecardStyle.detailed => 'Detailed',
        BroadcastScorecardStyle.fullBroadcastBar => 'Full broadcast bar',
      };

  static BroadcastScorecardStyle? fromWireValue(String value) {
    for (final style in BroadcastScorecardStyle.values) {
      if (style.wireValue == value) return style;
    }
    return null;
  }
}

extension BroadcastOverlayJson on BroadcastOverlay {
  String get wireValue => switch (this) {
        BroadcastOverlay.scorecard => 'scorecard',
        BroadcastOverlay.ticker => 'ticker',
        BroadcastOverlay.lowerThird => 'lowerThird',
        BroadcastOverlay.lastBall => 'lastBall',
      };

  static BroadcastOverlay? fromWireValue(String value) {
    for (final overlay in BroadcastOverlay.values) {
      if (overlay.wireValue == value) return overlay;
    }
    return null;
  }
}

class TimedBroadcastMessage {
  const TimedBroadcastMessage({
    required this.kind,
    required this.title,
    this.detail,
    required this.createdAt,
    required this.expiresAt,
    this.mediaUrl,
    this.mediaType,
    this.loop = false,
    this.slot,
    this.triggeringEventIdentity,
  });

  final String kind;
  final String title;
  final String? detail;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? mediaUrl;
  final String? mediaType;
  final bool loop;
  final String? slot;
  final String? triggeringEventIdentity;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  Map<String, Object?> toJson() => {
        'kind': kind,
        'title': title,
        'detail': detail,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'loop': loop,
        'slot': slot,
        'triggeringEventIdentity': triggeringEventIdentity,
      };
}

const Map<String, Map<String, double>> defaultBroadcastLayout = {
  // Compact full broadcast bar sits above the ticker at the bottom by default.
  'scorecard': {'x': 3, 'y': 82.5, 'width': 94, 'height': 8},
  'ticker': {'x': 3, 'y': 91.5, 'width': 94, 'height': 6.5},
  'lowerThird': {'x': 3, 'y': 51, 'width': 58, 'height': 17},
  'lastBall': {'x': 25, 'y': 22, 'width': 50, 'height': 42},
};

/// Layer order is bottom-to-top; later items are drawn above earlier items.
const List<String> defaultBroadcastLayerOrder = [
  'scorecard',
  'ticker',
  'lowerThird',
  'lastBall',
];


/// Event graphic assignment slots. Custom slots are presentation-only and
/// deliberately have no connection to scoring writes.
const Map<String, String> defaultBroadcastEventSlotNames = {
  'FOUR': 'FOUR',
  'SIX': 'SIX',
  'WICKET': 'WICKET',
  'CUSTOM_1': 'Custom Event 1',
  'CUSTOM_2': 'Custom Event 2',
  'CUSTOM_3': 'Custom Event 3',
};

extension _StringSetAddNullable on Set<String> {
  void addIfNotNull(String? value) {
    if (value != null) add(value);
  }
}

/// Single source of truth for broadcast presentation state.
///
/// It accepts an already-recalculated snapshot and must never write scoring
/// events or recalculate cricket rules itself.
class BroadcastStateCoordinator extends ChangeNotifier {
  BroadcastSnapshot? _snapshot;
  final Map<BroadcastOverlay, bool> _overlayEnabled = {
    for (final overlay in BroadcastOverlay.values) overlay: false,
  };

  TimedBroadcastMessage? _ticker;
  TimedBroadcastMessage? _lowerThird;
  TimedBroadcastMessage? _event;
  Timer? _tickerTimer;
  Timer? _lowerThirdTimer;
  Timer? _eventTimer;
  DateTime _updatedAt = DateTime.now();
  BroadcastScorecardStyle _scorecardStyle =
      BroadcastScorecardStyle.fullBroadcastBar;
  Map<String, Map<String, double>> _layout = {
    for (final entry in defaultBroadcastLayout.entries)
      entry.key: Map<String, double>.of(entry.value),
  };
  Map<BroadcastScorecardStyle, Map<String, double>> _scorecardGeometries = {
    for (final style in BroadcastScorecardStyle.values)
      style: Map<String, double>.of(defaultBroadcastLayout['scorecard']!),
  };
  final Map<String, bool> _layerVisibility = {
    for (final layer in defaultBroadcastLayerOrder) layer: true,
  };
  final Map<String, bool> _layerLocked = {
    for (final layer in defaultBroadcastLayerOrder) layer: false,
  };
  List<String> _layerOrder = List<String>.of(defaultBroadcastLayerOrder);
  Map<String, Map<String, Object?>> _eventMediaSettings = {
    for (final entry in defaultBroadcastEventSlotNames.entries)
      entry.key: {
        'name': entry.value,
        'mediaId': null,
        'mediaName': null,
        'mediaUrl': null,
        'mediaType': null,
        'loop': false,
        'durationSeconds': 5,
      },
  };
  BroadcastFullScreenSettings _fullScreenScorecardSettings =
      const BroadcastFullScreenSettings();

  Map<String, Object?> get fullScreenScorecardSettings =>
      _fullScreenScorecardSettings.toJson();

  BroadcastFullScreenSettings get typedFullScreenScorecardSettings =>
      _fullScreenScorecardSettings;
  bool _automaticEventPlaybackEnabled = true;
  bool _hasSeededScoringEvents = false;
  final Set<String> _seenScoringEventIdentities = <String>{};

  BroadcastSnapshot? get snapshot => _snapshot;
  DateTime get updatedAt => _updatedAt;
  BroadcastScorecardStyle get scorecardStyle => _scorecardStyle;
  bool get automaticEventPlaybackEnabled => _automaticEventPlaybackEnabled;



  void setFullScreenScorecardSettings({
    bool? enabled,
    String? view,
    String? style,
    bool? transparent,
    bool? showCompactScorecard,
    String? playingXiMode,
    String? playingXiTeam,
    double? opacity,
    Map<String, Map<String, double>>? viewGeometries,
  }) {
    var next = _fullScreenScorecardSettings;
    if (enabled != null) next = next.copyWith(enabled: enabled);
    if (view != null) next = next.copyWith(view: view);
    if (style != null) next = next.copyWith(style: style);
    if (transparent != null) next = next.copyWith(transparent: transparent);
    if (showCompactScorecard != null) {
      next = next.copyWith(showCompactScorecard: showCompactScorecard);
    }
    if (playingXiMode != null) next = next.copyWith(playingXiMode: playingXiMode);
    if (playingXiTeam != null) next = next.copyWith(playingXiTeam: playingXiTeam);
    if (opacity != null) next = next.copyWith(opacity: opacity);
    if (viewGeometries != null) {
      final geometries = <String, BroadcastFullScreenGeometry>{};
      for (final entry in viewGeometries.entries) {
        geometries[entry.key] = BroadcastFullScreenGeometry.fromJson(entry.value);
      }
      next = next.copyWith(geometries: geometries);
    }
    if (!next.isValid) {
      throw ArgumentError('Invalid full-screen scorecard settings.');
    }
    if (_sameSettings(next.toJson(), _fullScreenScorecardSettings.toJson())) return;
    _fullScreenScorecardSettings = next;
    _changed();
  }

  void restoreFullScreenScorecardSettings(Object? raw) {
    if (raw is! Map) return;
    try {
      final normalized = <String, Object?>{
        'enabled': raw['enabled'] is bool ? raw['enabled'] : false,
        'view': raw['view'] is String ? raw['view'] : 'combined',
        'style': raw['style'] is String ? raw['style'] : 'traditional',
        'transparent': raw['transparent'] is bool ? raw['transparent'] : false,
        'showCompactScorecard': raw['showCompactScorecard'] is bool
            ? raw['showCompactScorecard']
            : false,
        'playingXiMode': raw['playingXiMode'] is String
            ? raw['playingXiMode']
            : 'both',
        'playingXiTeam': raw['playingXiTeam'] is String
            ? raw['playingXiTeam']
            : 'teamA',
        'opacity': raw['opacity'] is num ? raw['opacity'] : 100,
        'viewGeometries': raw['viewGeometries'] is Map
            ? raw['viewGeometries']
            : const {
                'combined': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
                'batting': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
                'bowling': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
                'playingXi': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
              },
      };
      final restored = BroadcastFullScreenSettings.fromJson(normalized);
      if (_sameSettings(restored.toJson(), _fullScreenScorecardSettings.toJson())) return;
      _fullScreenScorecardSettings = restored;
      _changed();
    } on FormatException {
      // Keep the current settings when a persisted settings document is invalid.
    }
  }

  bool _sameSettings(Map<String, Object?> left, Map<String, Object?> right) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      final rightValue = right[entry.key];
      final leftValue = entry.value;
      if (leftValue is Map && rightValue is Map) {
        if (!_sameSettings(
          Map<String, Object?>.from(leftValue),
          Map<String, Object?>.from(rightValue),
        )) return false;
      } else if (leftValue != rightValue) {
        return false;
      }
    }
    return true;
  }

omaticEventPlaybackEnabled == enabled) return;
    _automaticEventPlaybackEnabled = enabled;
    if (!enabled && _event?.triggeringEventIdentity != null) {
      _eventTimer?.cancel();
      _eventTimer = null;
      _event = null;
    }
    _changed();
  }

  void restoreAutomaticEventPlaybackEnabled(Object? value) {
    if (value is bool) setAutomaticEventPlaybackEnabled(value);
  }
  String? get tickerText => _active(_ticker)?.title;
  TimedBroadcastMessage? get ticker => _active(_ticker);
  TimedBroadcastMessage? get lowerThird => _active(_lowerThird);
  TimedBroadcastMessage? get event => _active(_event);

  Map<String, Map<String, double>> get layout => {
        for (final entry in _layout.entries)
          entry.key: Map<String, double>.unmodifiable(entry.value),
      };

  Map<BroadcastScorecardStyle, Map<String, double>> get scorecardGeometries => {
        for (final entry in _scorecardGeometries.entries)
          entry.key: Map<String, double>.unmodifiable(entry.value),
      };

  List<String> get layerOrder => List<String>.unmodifiable(_layerOrder);

  Map<String, Map<String, Object?>> get eventMediaSettings => {
        for (final entry in _eventMediaSettings.entries)
          entry.key: Map<String, Object?>.unmodifiable(entry.value),
      };

  String eventSlotName(String slot) {
    _requireEventSlot(slot);
    return _eventMediaSettings[slot]!['name'] as String;
  }

  void _requireEventSlot(String slot) {
    if (!defaultBroadcastEventSlotNames.containsKey(slot)) {
      throw ArgumentError.value(slot, 'slot', 'Unknown event media slot.');
    }
  }

  /// Saves a media assignment and playback settings for one event slot.
  /// Passing [clearMedia] removes its asset assignment but keeps slot settings.
  void setEventMediaSettings({
    required String slot,
    String? name,
    String? mediaId,
    String? mediaName,
    String? mediaUrl,
    String? mediaType,
    bool? loop,
    int? durationSeconds,
    bool clearMedia = false,
  }) {
    _requireEventSlot(slot);
    final next = Map<String, Object?>.of(_eventMediaSettings[slot]!);
    if (name != null) {
      final cleanName = name.trim();
      if (cleanName.isEmpty || cleanName.length > 48) {
        throw ArgumentError.value(name, 'name', 'Use 1–48 characters.');
      }
      if (slot.startsWith('CUSTOM_')) next['name'] = cleanName;
    }
    if (clearMedia) {
      next['mediaId'] = null;
      next['mediaName'] = null;
      next['mediaUrl'] = null;
      next['mediaType'] = null;
    }
    if (!clearMedia && mediaUrl != null) {
      if (!mediaUrl.startsWith('/broadcast/media/asset_') ||
          mediaUrl.contains('..') ||
          (mediaType != 'image' && mediaType != 'video')) {
        throw ArgumentError.value(mediaUrl, 'mediaUrl', 'Invalid local media URL.');
      }
      next['mediaUrl'] = mediaUrl;
      next['mediaType'] = mediaType;
    }
    if (!clearMedia && mediaId != null) next['mediaId'] = mediaId;
    if (!clearMedia && mediaName != null) next['mediaName'] = mediaName;
    if (loop != null) next['loop'] = loop;
    if (durationSeconds != null) {
      if (durationSeconds < 1 || durationSeconds > 120) {
        throw ArgumentError.value(durationSeconds, 'durationSeconds', 'Use 1–120 seconds.');
      }
      next['durationSeconds'] = durationSeconds;
    }
    _eventMediaSettings[slot] = next;
    _changed();
  }

  /// Restores persisted event media settings. Unknown slots and unsafe media
  /// paths are ignored so a bad settings file cannot escape the media folder.
  void restoreEventMediaSettings(Object? raw) {
    if (raw is! Map) return;
    final restored = {
      for (final entry in defaultBroadcastEventSlotNames.entries)
        entry.key: Map<String, Object?>.of(_eventMediaSettings[entry.key]!),
    };
    for (final entry in raw.entries) {
      if (entry.key is! String ||
          !defaultBroadcastEventSlotNames.containsKey(entry.key) ||
          entry.value is! Map) {
        continue;
      }
      final slot = entry.key as String;
      final value = entry.value as Map;
      final name = value['name'];
      if (slot.startsWith('CUSTOM_') && name is String &&
          name.trim().isNotEmpty && name.trim().length <= 48) {
        restored[slot]!['name'] = name.trim();
      }
      final mediaUrl = value['mediaUrl'];
      final mediaType = value['mediaType'];
      final mediaId = value['mediaId'];
      final mediaName = value['mediaName'];
      if (mediaUrl is String &&
          mediaUrl.startsWith('/broadcast/media/asset_') &&
          !mediaUrl.contains('..') &&
          (mediaType == 'image' || mediaType == 'video')) {
        restored[slot]!['mediaUrl'] = mediaUrl;
        restored[slot]!['mediaType'] = mediaType;
        if (mediaId is String) restored[slot]!['mediaId'] = mediaId;
        if (mediaName is String && mediaName.length <= 255) {
          restored[slot]!['mediaName'] = mediaName;
        }
      }
      if (value['loop'] is bool) restored[slot]!['loop'] = value['loop'];
      final duration = value['durationSeconds'];
      if (duration is num && duration >= 1 && duration <= 120) {
        restored[slot]!['durationSeconds'] = duration.toInt();
      }
    }
    _eventMediaSettings = restored;
    _changed();
  }

  Map<String, Map<String, Object?>> get layerSettings => {
        for (final layer in defaultBroadcastLayerOrder)
          layer: {
            'visible': _layerVisibility[layer] ?? true,
            'locked': _layerLocked[layer] ?? false,
            'zIndex': _layerOrder.indexOf(layer),
          },
      };

  bool isLayerVisible(String layer) {
    _requireLayer(layer);
    return _layerVisibility[layer] ?? true;
  }

  bool isLayerLocked(String layer) {
    _requireLayer(layer);
    return _layerLocked[layer] ?? false;
  }

  void _requireLayer(String layer) {
    if (!defaultBroadcastLayout.containsKey(layer)) {
      throw ArgumentError.value(layer, 'layer', 'Unknown broadcast layer.');
    }
  }

  void setLayerVisible(String layer, bool visible) {
    _requireLayer(layer);
    if (_layerVisibility[layer] == visible) return;
    _layerVisibility[layer] = visible;
    _changed();
  }

  void setLayerLocked(String layer, bool locked) {
    _requireLayer(layer);
    if (_layerLocked[layer] == locked) return;
    _layerLocked[layer] = locked;
    _changed();
  }

  void bringLayerForward(String layer) {
    _requireLayer(layer);
    final index = _layerOrder.indexOf(layer);
    if (index == _layerOrder.length - 1) return;
    final next = List<String>.of(_layerOrder);
    next[index] = next[index + 1];
    next[index + 1] = layer;
    _layerOrder = next;
    _changed();
  }

  void sendLayerBackward(String layer) {
    _requireLayer(layer);
    final index = _layerOrder.indexOf(layer);
    if (index <= 0) return;
    final next = List<String>.of(_layerOrder);
    next[index] = next[index - 1];
    next[index - 1] = layer;
    _layerOrder = next;
    _changed();
  }

  /// Restores per-layer visibility, locks and draw order from the saved workspace.
  void restoreLayerSettings({
    Map<String, bool> visibility = const {},
    Map<String, bool> locked = const {},
    List<String>? order,
  }) {
    for (final layer in {...visibility.keys, ...locked.keys}) {
      _requireLayer(layer);
    }
    if (order != null &&
        (order.length != defaultBroadcastLayerOrder.length ||
            order.toSet().length != defaultBroadcastLayerOrder.length ||
            !order.toSet().containsAll(defaultBroadcastLayerOrder))) {
      throw ArgumentError.value(
        order,
        'order',
        'Layer order must contain every layer exactly once.',
      );
    }
    var changed = false;
    for (final entry in visibility.entries) {
      if (_layerVisibility[entry.key] != entry.value) {
        _layerVisibility[entry.key] = entry.value;
        changed = true;
      }
    }
    for (final entry in locked.entries) {
      if (_layerLocked[entry.key] != entry.value) {
        _layerLocked[entry.key] = entry.value;
        changed = true;
      }
    }
    if (order != null && !_sameLayerOrder(_layerOrder, order)) {
      _layerOrder = List<String>.of(order);
      changed = true;
    }
    if (changed) _changed();
  }

  bool _sameLayerOrder(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  /// Updates any supplied layer rectangles, expressed as percentages of a
  /// 16:9 output canvas. Unknown layer names or invalid geometry are rejected.
  void setLayout(Map<String, Map<String, double>> updates) {
    final next = {
      for (final entry in _layout.entries)
        entry.key: Map<String, double>.of(entry.value),
    };
    for (final entry in updates.entries) {
      if (!defaultBroadcastLayout.containsKey(entry.key)) {
        throw ArgumentError.value(entry.key, 'layer', 'Unknown broadcast layer.');
      }
      final rect = entry.value;
      const fields = ['x', 'y', 'width', 'height'];
      if (rect.keys.toSet().length != fields.length ||
          !fields.every(rect.containsKey)) {
        throw ArgumentError.value(rect, 'layout', 'Each layer needs x, y, width, and height.');
      }
      final x = rect['x']!;
      final y = rect['y']!;
      final width = rect['width']!;
      final height = rect['height']!;
      if (![x, y, width, height].every((value) => value.isFinite) ||
          x < 0 || y < 0 || width <= 0 || height <= 0 ||
          x + width > 100.01 || y + height > 100.01) {
        throw ArgumentError.value(rect, 'layout', 'Layer geometry must fit inside the 0–100% canvas.');
      }
      next[entry.key] = Map<String, double>.of(rect);
    }
    _layout = next;
    if (updates.containsKey('scorecard')) {
      _scorecardGeometries[_scorecardStyle] =
          Map<String, double>.of(_layout['scorecard']!);
    }
    _changed();
  }

  void resetLayout() {
    _layout = {
      for (final entry in defaultBroadcastLayout.entries)
        entry.key: Map<String, double>.of(entry.value),
    };
    _scorecardGeometries[_scorecardStyle] =
        Map<String, double>.of(defaultBroadcastLayout['scorecard']!);
    _changed();
  }

  void setScorecardStyle(BroadcastScorecardStyle style) {
    if (_scorecardStyle == style) return;
    _scorecardGeometries[_scorecardStyle] =
        Map<String, double>.of(_layout['scorecard']!);
    _scorecardStyle = style;
    _layout['scorecard'] = Map<String, double>.of(
      _scorecardGeometries[style] ?? defaultBroadcastLayout['scorecard']!,
    );
    _changed();
  }

  /// Restores saved geometry for any scorecard styles. Missing styles keep
  /// their current/default geometry; the active style is applied immediately.
  void setScorecardGeometries(
    Map<BroadcastScorecardStyle, Map<String, double>> geometries,
  ) {
    final next = {
      for (final entry in _scorecardGeometries.entries)
        entry.key: Map<String, double>.of(entry.value),
    };
    const fields = ['x', 'y', 'width', 'height'];
    for (final entry in geometries.entries) {
      final rect = entry.value;
      final x = rect['x'];
      final y = rect['y'];
      final width = rect['width'];
      final height = rect['height'];
      if (rect.keys.toSet().length != fields.length ||
          !fields.every(rect.containsKey) ||
          x == null ||
          y == null ||
          width == null ||
          height == null) {
        throw ArgumentError.value(
          rect,
          'scorecardGeometries',
          'Each scorecard style needs numeric x, y, width, and height.',
        );
      }
      if (![x, y, width, height].every((value) => value.isFinite) ||
          x < 0 ||
          y < 0 ||
          width <= 0 ||
          height <= 0 ||
          x + width > 100.01 ||
          y + height > 100.01) {
        throw ArgumentError.value(
          rect,
          'scorecardGeometries',
          'Scorecard style geometry must fit inside the 0–100% canvas.',
        );
      }
      next[entry.key] = Map<String, double>.of(rect);
    }
    _scorecardGeometries = next;
    _layout['scorecard'] = Map<String, double>.of(
      _scorecardGeometries[_scorecardStyle]!,
    );
    _changed();
  }

  bool isOverlayEnabled(BroadcastOverlay overlay) =>
      _overlayEnabled[overlay] ?? false;

  /// Receives display-only state and detects genuinely new scoring events.
  /// The first ready snapshot per context seeds historical identities without
  /// replaying them. Subsequent refreshes can trigger only an unseen latest
  /// event, and only when the snapshot says it represents the live innings.
  void updateSnapshot(BroadcastSnapshot snapshot) {
    final previousContext = _snapshot?.scoringContextIdentity;
    final nextContext = snapshot.scoringContextIdentity;

    if (snapshot.ready && nextContext != null) {
      final contextChanged =
          previousContext != null && previousContext != nextContext;
      if (!_hasSeededScoringEvents || previousContext != nextContext) {
        _seenScoringEventIdentities
          ..addAll(snapshot.activeScoringEventIdentities)
          ..addIfNotNull(snapshot.latestScoringEventIdentity)
          ..addAll(
            snapshot.scoringEventCandidates.map((event) => event.identity),
          );
        _hasSeededScoringEvents = true;
        if (contextChanged && _event?.triggeringEventIdentity != null) {
          _eventTimer?.cancel();
          _eventTimer = null;
          _event = null;
        }
      } else {
        final candidates = snapshot.scoringEventCandidates.isNotEmpty
            ? snapshot.scoringEventCandidates
            : snapshot.latestScoringEventIdentity != null &&
                    snapshot.latestScoringEventKind != null
                ? [
                    BroadcastScoringEvent(
                      identity: snapshot.latestScoringEventIdentity!,
                      kind: snapshot.latestScoringEventKind!,
                      detail: snapshot.latestScoringEventDetail,
                    ),
                  ]
                : const <BroadcastScoringEvent>[];
        final unseenCandidates = candidates
            .where((event) =>
                !_seenScoringEventIdentities.contains(event.identity))
            .toList(growable: false);

        final activeTriggerIdentity = _event?.triggeringEventIdentity;
        if (activeTriggerIdentity != null &&
            activeTriggerIdentity.startsWith('$nextContext/') &&
            !snapshot.activeScoringEventIdentities
                .contains(activeTriggerIdentity)) {
          // Undo removed the exact ball that started this animation.
          // Other undo operations leave the animation alone.
          _eventTimer?.cancel();
          _eventTimer = null;
          _event = null;
        }

        _seenScoringEventIdentities
          ..addAll(snapshot.activeScoringEventIdentities)
          ..addIfNotNull(snapshot.latestScoringEventIdentity)
          ..addAll(unseenCandidates.map((event) => event.identity));

        if (_automaticEventPlaybackEnabled &&
            snapshot.automaticEventsEligible) {
          for (final event in unseenCandidates) {
            triggerEvent(
              kind: event.kind,
              detail: event.detail,
              triggeringEventIdentity: event.identity,
            );
          }
        }
      }
    }

    _snapshot = snapshot;
    _changed();
  }

  void setOverlayEnabled(BroadcastOverlay overlay, bool enabled) {
    if (isOverlayEnabled(overlay) == enabled) return;
    _overlayEnabled[overlay] = enabled;
    _changed();
  }

  void setAllOverlaysEnabled(bool enabled) {
    var changed = false;
    for (final overlay in BroadcastOverlay.values) {
      if (_overlayEnabled[overlay] != enabled) {
        _overlayEnabled[overlay] = enabled;
        changed = true;
      }
    }
    if (changed) _changed();
  }

  void showTicker(
    String text, {
    Duration duration = const Duration(seconds: 12),
  }) {
    final clean = text.trim();
    if (clean.isEmpty) {
      clearTicker();
      return;
    }
    _tickerTimer?.cancel();
    final message = _newMessage('ticker', clean, duration: duration);
    _ticker = message;
    _overlayEnabled[BroadcastOverlay.ticker] = true;
    _tickerTimer = _expiryTimer(duration, () {
      if (identical(_ticker, message)) {
        _ticker = null;
        _tickerTimer = null;
        _changed();
      }
    });
    _changed();
  }

  void clearTicker() {
    final hadValue = _ticker != null;
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _ticker = null;
    if (hadValue) _changed();
  }

  void showLowerThird({
    required String title,
    String? detail,
    Duration duration = const Duration(seconds: 8),
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      clearLowerThird();
      return;
    }
    _lowerThirdTimer?.cancel();
    final message = _newMessage(
      'lowerThird',
      cleanTitle,
      detail: detail?.trim(),
      duration: duration,
    );
    _lowerThird = message;
    _overlayEnabled[BroadcastOverlay.lowerThird] = true;
    _lowerThirdTimer = _expiryTimer(duration, () {
      if (identical(_lowerThird, message)) {
        _lowerThird = null;
        _lowerThirdTimer = null;
        _changed();
      }
    });
    _changed();
  }

  void clearLowerThird() {
    final hadValue = _lowerThird != null;
    _lowerThirdTimer?.cancel();
    _lowerThirdTimer = null;
    _lowerThird = null;
    if (hadValue) _changed();
  }

  void triggerEvent({
    required String kind,
    String? detail,
    Duration? duration,
    String? mediaUrl,
    String? mediaType,
    bool? loop,
    String? triggeringEventIdentity,
  }) {
    final cleanKind = kind.trim().toUpperCase();
    if (cleanKind.isEmpty) {
      throw ArgumentError.value(kind, 'kind', 'Must not be empty.');
    }
    final slot = switch (cleanKind) {
      'FOUR' => 'FOUR',
      'SIX' => 'SIX',
      'WICKET' => 'WICKET',
      'CUSTOM' || 'CUSTOM_1' => 'CUSTOM_1',
      'CUSTOM_2' => 'CUSTOM_2',
      'CUSTOM_3' => 'CUSTOM_3',
      _ => null,
    };
    final settings = slot == null ? null : _eventMediaSettings[slot];
    final title = slot?.startsWith('CUSTOM_') == true
        ? settings!['name'] as String
        : cleanKind;
    final selectedMediaUrl = mediaUrl ?? settings?['mediaUrl'] as String?;
    final selectedMediaType = mediaType ?? settings?['mediaType'] as String?;
    final shouldLoop = loop ?? settings?['loop'] == true;
    final effectiveDuration = duration ??
        Duration(seconds: (settings?['durationSeconds'] as int?) ?? 5);
    if (effectiveDuration <= Duration.zero) {
      throw ArgumentError.value(effectiveDuration, 'duration', 'Must be positive.');
    }
    _eventTimer?.cancel();
    final message = _newMessage(
      'event',
      title,
      detail: detail?.trim(),
      duration: effectiveDuration,
      mediaUrl: selectedMediaUrl,
      mediaType: selectedMediaType,
      loop: shouldLoop,
      slot: slot,
      triggeringEventIdentity: triggeringEventIdentity,
    );
    _event = message;
    _overlayEnabled[BroadcastOverlay.lastBall] = true;
    _eventTimer = _expiryTimer(effectiveDuration, () {
      if (identical(_event, message)) {
        _event = null;
        _eventTimer = null;
        _changed();
      }
    });
    _changed();
  }

  void clearEvent() {
    final hadValue = _event != null;
    _eventTimer?.cancel();
    _eventTimer = null;
    _event = null;
    if (hadValue) _changed();
  }

  void clearMessages() {
    final hadValue = _ticker != null || _lowerThird != null || _event != null;
    _tickerTimer?.cancel();
    _lowerThirdTimer?.cancel();
    _eventTimer?.cancel();
    _tickerTimer = null;
    _lowerThirdTimer = null;
    _eventTimer = null;
    _ticker = null;
    _lowerThird = null;
    _event = null;
    if (hadValue) _changed();
  }

  Map<String, Object?> toJson({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    return {
      'version': 1,
      'updatedAt': _updatedAt.toIso8601String(),
      'snapshot': _snapshot?.toJson(),
      'scorecardStyle': _scorecardStyle.wireValue,
      'scorecardGeometries': {
        for (final entry in scorecardGeometries.entries)
          entry.key.wireValue: entry.value,
      },
      'layerSettings': layerSettings,
      'eventMediaSettings': eventMediaSettings,
      'automaticEventPlaybackEnabled': automaticEventPlaybackEnabled,
      'fullScreenScorecardSettings': fullScreenScorecardSettings,
      'layout': layout,
      'overlays': {
        for (final overlay in BroadcastOverlay.values)
          overlay.wireValue: isOverlayEnabled(overlay),
      },
      'ticker': _active(_ticker, now: currentTime)?.toJson(),
      'lowerThird': _active(_lowerThird, now: currentTime)?.toJson(),
      'event': _active(_event, now: currentTime)?.toJson(),
    };
  }

  TimedBroadcastMessage? _active(
    TimedBroadcastMessage? message, {
    DateTime? now,
  }) {
    if (message == null || message.isExpired(now ?? DateTime.now())) {
      return null;
    }
    return message;
  }

  TimedBroadcastMessage _newMessage(
    String kind,
    String title, {
    String? detail,
    required Duration duration,
    String? mediaUrl,
    String? mediaType,
    bool loop = false,
    String? slot,
    String? triggeringEventIdentity,
  }) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'Must be positive.');
    }
    final createdAt = DateTime.now();
    return TimedBroadcastMessage(
      kind: kind,
      title: title,
      detail: detail == null || detail.isEmpty ? null : detail,
      createdAt: createdAt,
      expiresAt: createdAt.add(duration),
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      loop: loop,
      slot: slot,
      triggeringEventIdentity: triggeringEventIdentity,
    );
  }

  Timer _expiryTimer(Duration duration, VoidCallback onExpire) =>
      Timer(duration, onExpire);

  void _changed() {
    _updatedAt = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _lowerThirdTimer?.cancel();
    _eventTimer?.cancel();
    super.dispose();
  }
}
