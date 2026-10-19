import 'package:flutter_riverpod/legacy.dart';

import '../state/broadcast_state_coordinator.dart';
import 'broadcast_live_snapshot_provider.dart';

/// App-scoped broadcast presentation state. The snapshot bridge feeds it from
/// the same recalculated state used by the live scoring screen.
final broadcastStateCoordinatorProvider =
    ChangeNotifierProvider<BroadcastStateCoordinator>((ref) {
  final coordinator = BroadcastStateCoordinator();

  ref.listen(broadcastLiveSnapshotProvider, (previous, next) {
    next.whenData(coordinator.updateSnapshot);
  });
  ref.read(broadcastLiveSnapshotProvider).whenData(coordinator.updateSnapshot);

  ref.onDispose(coordinator.dispose);
  return coordinator;
});
