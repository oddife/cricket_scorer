import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/players/models/player.dart';
import '../../domain/teams/models/team.dart';
import '../../domain/teams/models/team_player.dart';

class SupabaseTeamPlayerTransport {
  const SupabaseTeamPlayerTransport(this._client);

  final SupabaseClient? _client;

  Future<void> uploadTeam({
    required Team team,
    required String syncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    await client.from('teams').upsert(
      <String, dynamic>{
        'sync_id': syncId,
        'source_installation_id': installationId,
        'local_id': team.id,
        'name': team.name,
        'short_name': team.shortName,
        'logo_path': team.logoPath,
        'is_active': team.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'sync_id',
    );
  }

  Future<void> uploadPlayer({
    required Player player,
    required String syncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    await client.from('players').upsert(
      <String, dynamic>{
        'sync_id': syncId,
        'source_installation_id': installationId,
        'local_id': player.id,
        'name': player.name,
        'display_name': player.displayName,
        'photo_path': player.photoPath,
        'jersey_number': player.jerseyNumber,
        'batting_style': player.battingStyle.dbValue,
        'bowling_style': player.bowlingStyle.dbValue,
        'is_active': player.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'sync_id',
    );
  }

  Future<void> uploadTeamPlayer({
    required TeamPlayer membership,
    required String teamSyncId,
    required String playerSyncId,
    required String syncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    await client.from('team_players').upsert(
      <String, dynamic>{
        'sync_id': syncId,
        'source_installation_id': installationId,
        'local_id': membership.id,
        'team_sync_id': teamSyncId,
        'player_sync_id': playerSyncId,
        'jersey_number': membership.jerseyNumber,
        'is_active': membership.isActive,
      },
      onConflict: 'sync_id',
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
