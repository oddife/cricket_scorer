import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/tournaments/models/tournament.dart';
import '../../domain/tournaments/models/tournament_points_rules.dart';
import '../../domain/teams/models/team.dart';

class SupabaseTournamentTransport {
  const SupabaseTournamentTransport(this._client);

  final SupabaseClient? _client;

  Future<void> uploadTournament({
    required Tournament tournament,
    required String syncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    await client.from('tournaments').upsert(
      <String, dynamic>{
        'sync_id': syncId,
        'source_installation_id': installationId,
        'local_id': tournament.id,
        'name': tournament.name,
        'tournament_type': tournament.type.dbValue,
        'logo_path': tournament.logoPath,
        'start_date': tournament.startDate?.toIso8601String(),
        'end_date': tournament.endDate?.toIso8601String(),
        'is_active': tournament.isActive,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'sync_id',
    );
  }

  Future<void> uploadTournamentTeams({
    required String tournamentSyncId,
    required List<Team> teams,
    required Future<String> Function(int teamId) teamSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    for (final team in teams) {
      await client.from('tournament_teams').upsert(
        <String, dynamic>{
          'tournament_sync_id': tournamentSyncId,
          'team_sync_id': await teamSyncId(team.id),
        },
        onConflict: 'tournament_sync_id,team_sync_id',
      );
    }
  }

  Future<void> uploadPointsRules({
    required TournamentPointsRules rules,
    required String tournamentSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    await client.from('tournament_points_rules').upsert(
      <String, dynamic>{
        'tournament_sync_id': tournamentSyncId,
        'win_points': rules.winPoints,
        'tie_points': rules.tiePoints,
        'no_result_points': rules.noResultPoints,
        'loss_points': rules.lossPoints,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'tournament_sync_id',
    );
  }

  SupabaseClient _requireAuthenticatedClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured. Sync remains offline.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('Supabase sync requires an authenticated scorer.');
    }
    return client;
  }
}
