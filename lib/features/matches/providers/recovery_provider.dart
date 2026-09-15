import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/sync/supabase_recovery_transport.dart';
import '../../../core/supabase/supabase_client_provider.dart';

final supabaseRecoveryTransportProvider = Provider<SupabaseRecoveryTransport>((ref) {
  return SupabaseRecoveryTransport(ref.watch(supabaseClientProvider));
});

final remoteMatchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(supabaseRecoveryTransportProvider).listMatches();
});
