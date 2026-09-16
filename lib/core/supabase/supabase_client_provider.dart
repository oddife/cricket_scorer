import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/theme_mode_provider.dart';
import 'supabase_config.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  if (!SupabaseConfig.isConfiguredWith(preferences)) return null;
  return Supabase.instance.client;
});
