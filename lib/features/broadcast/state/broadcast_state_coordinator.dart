import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/broadcast_snapshot.dart';

enum BroadcastOverlay {
  scorecard,
  ticker,
  lowerThird,
  lastBall,
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
  });

  final String kind;
  final String title;
  final String? detail;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  Map<String, Object?> toJson() => {
        'kind': kind,
        'title': title,
        'detail': detail,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };
}

const Map<String, Map<String, double>> defaultBroadcastLayout = {
  // Compact full broadcast bar sits above the ticker at the bottom by default.
  'scorecard': {'x': 3, 'y': 82.5, 'width': 94, 'height': 8},
  'ticker': {'x': 3, 'y': 91.5, 'width': 94, 'height': 6.5},
  'lowerThird': {'x': 3, 'y': 51, 'width': 58, 'height': 17},
  'lastBall': {'x': 25, 'y': 22, 'width': 50, 'height': 42},
};

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
  Map<String, Map<String, double>> _layout = {
    for (final entry in defaultBroadcastLayout.entries)
      entry.key: Map<String, double>.of(entry.value),
  };

  BroadcastSnapshot? get snapshot => _snapshot;
  DateTime get updatedAt => _updatedAt;
  String? get tickerText => _active(_ticker)?.title;
  TimedBroadcastMessage? get ticker => _active(_ticker);
  TimedBroadcastMessage? get lowerThird => _active(_lowerThird);
  TimedBroadcastMessage? get event => _active(_event);

  Map<String, Map<String, double>> get layout => {
        for (final entry in _layout.entries)
          entry.key: Map<String, double>.unmodifiable(entry.value),
      };

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
    _changed();
  }

  void resetLayout() {
    _layout = {
      for (final entry in defaultBroadcastLayout.entries)
        entry.key: Map<String, double>.of(entry.value),
    };
    _changed();
  }

  bool isOverlayEnabled(BroadcastOverlay overlay) =>
      _overlayEnabled[overlay] ?? false;

  void updateSnapshot(BroadcastSnapshot snapshot) {
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
    Duration duration = const Duration(seconds: 5),
  }) {
    final cleanKind = kind.trim().toUpperCase();
    if (cleanKind.isEmpty) {
      throw ArgumentError.value(kind, 'kind', 'Must not be empty.');
    }
    _eventTimer?.cancel();
    final message = _newMessage(
      'event',
      cleanKind,
      detail: detail?.trim(),
      duration: duration,
    );
    _event = message;
    _overlayEnabled[BroadcastOverlay.lastBall] = true;
    _eventTimer = _expiryTimer(duration, () {
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
