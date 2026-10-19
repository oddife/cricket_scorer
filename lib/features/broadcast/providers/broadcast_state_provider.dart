import 'package:flutter_riverpod/legacy.dart';

import '../state/broadcast_state_coordinator.dart';

/// App-scoped broadcast presentation state. Keep one ProviderScope/coordinator
/// for the desktop session when native multi-window support is integrated.
final broadcastStateCoordinatorProvider =
    ChangeNotifierProvider<BroadcastStateCoordinator>((ref) {
  final coordinator = BroadcastStateCoordinator();
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
