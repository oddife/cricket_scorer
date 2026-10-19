import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../state/broadcast_state_coordinator.dart';
import 'broadcast_live_snapshot_provider.dart';

/// App-scoped broadcast presentation state. The snapshot bridge feeds it from
/// the same recalculated state used by the live scoring screen.
final broadcastStateCoordinatorProvider =
    ChangeNotifierProvider<BroadcastStateCoordinator>((ref) {
  final coordinator = BroadcastStateCoordinator();

  ref.listen(broadcastLiveSnapshotProvider, (previous, next) {
    final snapshot = next.asData?.value;
    if (snapshot != null) coordinator.updateSnapshot(snapshot);
  });
  final initialSnapshot =
      ref.read(broadcastLiveSnapshotProvider).asData?.value;
  if (initialSnapshot != null) coordinator.updateSnapshot(initialSnapshot);

  ref.onDispose(coordinator.dispose);
  return coordinator;
});
