import '../state/broadcast_state_coordinator.dart';

class BroadcastHttpServerBase {
  Uri? get baseUri => null;
  bool get isRunning => false;

  Future<Uri> start(
    BroadcastStateCoordinator coordinator, {
    int port = 3113,
  }) =>
      Future.error(
        UnsupportedError(
          'The Cricket Scorer broadcast server is only available on native desktop.',
        ),
      );

  Future<void> close() async {}
}

BroadcastHttpServerBase createBroadcastHttpServer() =>
    BroadcastHttpServerBase();
