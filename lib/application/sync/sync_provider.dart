import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../core/supabase/supabase_client_provider.dart';
import 'supabase_ball_event_transport.dart';
import 'sync_worker.dart';

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  return SyncWorker(
    syncQueueRepository: ref.watch(syncQueueRepositoryProvider),
    ballEventRepository: ref.watch(ballEventRepositoryProvider),
    inningsRepository: ref.watch(inningsRepositoryProvider),
    transport: SupabaseBallEventTransport(ref.watch(supabaseClientProvider)),
  );
});
