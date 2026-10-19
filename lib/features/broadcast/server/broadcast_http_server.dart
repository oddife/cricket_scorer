import '../state/broadcast_state_coordinator.dart';
import 'broadcast_http_server_stub.dart'
    if (dart.library.io) 'broadcast_http_server_io.dart' as platform;

class BroadcastHttpServer {
  BroadcastHttpServer() : _implementation = platform.createBroadcastHttpServer();

  final platform.BroadcastHttpServerBase _implementation;

  Uri? get baseUri => _implementation.baseUri;
  bool get isRunning => _implementation.isRunning;

  Future<Uri> start(
    BroadcastStateCoordinator coordinator, {
    int port = 3113,
  }) =>
      _implementation.start(coordinator, port: port);

  Future<void> close() => _implementation.close();
}
