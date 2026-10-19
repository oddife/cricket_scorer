import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import 'supabase_recovery_importer.dart';

final supabaseRecoveryImporterProvider = Provider<SupabaseRecoveryImporter>((ref) {
  return SupabaseRecoveryImporter(ref.watch(appDatabaseProvider));
});
