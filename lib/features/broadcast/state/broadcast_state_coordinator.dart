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

  BroadcastSnapshot? get snapshot => _snapshot;
  DateTime get updatedAt => _updatedAt;
  String? get tickerText => _active(_ticker)?.title;
  TimedBroadcastMessage? get ticker => _active(_ticker);
  TimedBroadcastMessage? get lowerThird => _active(_lowerThird);
  TimedBroadcastMessage? get event => _active(_event);

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
