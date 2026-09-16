import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../core/supabase/supabase_auth_provider.dart';
import '../../core/supabase/supabase_client_provider.dart';
import 'supabase_ball_event_transport.dart';
import 'supabase_match_transport.dart';
import 'supabase_recovery_transport.dart';
import 'supabase_team_player_transport.dart';
import 'supabase_tournament_transport.dart';
import 'sync_worker.dart';

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SyncWorker(
    syncQueueRepository: ref.watch(syncQueueRepositoryProvider),
    catalogSyncQueueRepository: ref.watch(catalogSyncQueueRepositoryProvider),
    syncIdentityRepository: ref.watch(syncIdentityRepositoryProvider),
    ballEventRepository: ref.watch(ballEventRepositoryProvider),
    inningsRepository: ref.watch(inningsRepositoryProvider),
    matchRepository: ref.watch(matchRepositoryProvider),
    teamRepository: ref.watch(teamRepositoryProvider),
    playerRepository: ref.watch(playerRepositoryProvider),
    teamPlayerRepository: ref.watch(teamPlayerRepositoryProvider),
    tournamentRepository: ref.watch(tournamentRepositoryProvider),
    tournamentTeamRepository: ref.watch(tournamentTeamRepositoryProvider),
    tournamentPointsRepository: ref.watch(tournamentPointsRepositoryProvider),
    transport: SupabaseBallEventTransport(client),
    matchTransport: SupabaseMatchTransport(client),
    teamPlayerTransport: SupabaseTeamPlayerTransport(client),
    tournamentTransport: SupabaseTournamentTransport(client),
    authService: ref.watch(supabaseAuthServiceProvider),
  );
});

final supabaseRecoveryTransportProvider = Provider<SupabaseRecoveryTransport>((ref) {
  return SupabaseRecoveryTransport(ref.watch(supabaseClientProvider));
});
