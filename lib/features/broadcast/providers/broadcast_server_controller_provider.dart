import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../server/broadcast_http_server.dart';
import '../state/broadcast_state_coordinator.dart';
import 'broadcast_state_provider.dart';

/// App-scoped loopback server used by native controls and OBS/vMix browser
/// sources. It intentionally binds only on Windows in this first release.
class BroadcastServerController extends ChangeNotifier {
  BroadcastServerController({
    required BroadcastHttpServer server,
    required BroadcastStateCoordinator coordinator,
    required this.isSupported,
  })  : _server = server,
        _coordinator = coordinator;

  final BroadcastHttpServer _server;
  final BroadcastStateCoordinator _coordinator;
  final bool isSupported;

  bool _starting = false;
  String? _error;

  bool get isRunning => _server.isRunning;
  bool get isStarting => _starting;
  Uri? get baseUri => _server.baseUri;
  String? get error => _error;

  Future<void> start() async {
    if (!isSupported) {
      _error = 'Broadcast server is available in the native Windows app.';
      notifyListeners();
      return;
    }
    if (_server.isRunning || _starting) return;

    _starting = true;
    _error = null;
    notifyListeners();

    Object? lastError;
    try {
      // Prefer the documented port but allow a nearby fallback if another
      // process is already listening. Always display the actual chosen URL.
      for (var port = 3113; port <= 3118; port++) {
        try {
          await _server.start(_coordinator, port: port);
          _error = null;
          return;
        } catch (error) {
          lastError = error;
        }
      }

      _error = 'Unable to start the broadcast server: $lastError';
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (!_server.isRunning) return;
    _error = null;
    try {
      await _server.close();
    } catch (error) {
      _error = 'Unable to stop the broadcast server: $error';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_server.close());
    super.dispose();
  }
}

final broadcastServerControllerProvider =
    ChangeNotifierProvider<BroadcastServerController>((ref) {
  final controller = BroadcastServerController(
    server: BroadcastHttpServer(),
    coordinator: ref.watch(broadcastStateCoordinatorProvider),
    isSupported:
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows,
  );
  return controller;
});
