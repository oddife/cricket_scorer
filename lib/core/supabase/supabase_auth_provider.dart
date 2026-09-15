import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_auth_service.dart';
import 'supabase_client_provider.dart';

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService(ref.watch(supabaseClientProvider));
});
