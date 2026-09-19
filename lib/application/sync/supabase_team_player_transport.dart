import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/entity_identity_repository.dart';
import '../../domain/players/models/player.dart';
import '../../domain/teams/models/team.dart';
import '../../domain/teams/models/team_player.dart';

class SupabaseTeamPlayerTransport {
  const SupabaseTeamPlayerTransport(this._client, [this._entityIdentityRepository]);

  final SupabaseClient? _client;
  final EntityIdentityRepository? _entityIdentityRepository;

  Future<void> uploadTeam({
    required Team team,
    required String syncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    await _adoptRemoteIdentity(client, 'teams', 'team', team.id, syncId);
    final identity = await _entityIdentityRepository?.ensure('team', team.id);
    final appId = identity?.appId ?? syncId;
    final payload = <String, dynamic>{
      'app_id': appId,
      if (identity?.globalId != null) 'global_id': identity!.globalId,
      'sync_id': syncId,
      'source_installation_id': installationId,
      'local_id': team.id,
      'name': team.name,
      'short_name': team.shortName,
      'logo_path': team.logoPath,
      'is_active': team.isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = await client.from('teams').upsert(payload, onConflict: 'app_id').select('global_id').single();
    final globalId = row['global_id']?.toString();
    if (globalId != null && globalId.isNotEmpty) {
      await _entityIdentityRepository?.setGlobalId(entityType: 'team', localId: team.id, globalId: globalId);
    }
  }

  Future<void> uploadPlayer({
    required Player player,
    required String syncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    await _adoptRemoteIdentity(client, 'players', 'player', player.id, syncId);
    final identity = await _entityIdentityRepository?.ensure('player', player.id);
    final appId = identity?.appId ?? syncId;
    final payload = <String, dynamic>{
      'app_id': appId,
      if (identity?.globalId != null) 'global_id': identity!.globalId,
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
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = await client.from('players').upsert(payload, onConflict: 'app_id').select('global_id').single();
    final globalId = row['global_id']?.toString();
    if (globalId != null && globalId.isNotEmpty) {
      await _entityIdentityRepository?.setGlobalId(entityType: 'player', localId: player.id, globalId: globalId);
    }
  }

  Future<void> uploadTeamPlayer({
    required TeamPlayer membership,
    required String teamSyncId,
    required String playerSyncId,
    required String syncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    final membershipIdentity = await _entityIdentityRepository?.ensure('team_player', membership.id);
    final teamIdentity = await _entityIdentityRepository?.ensure('team', membership.teamId);
    final playerIdentity = await _entityIdentityRepository?.ensure('player', membership.playerId);
    final teamGlobalId = await _requireGlobalId('team', membership.teamId, teamIdentity?.globalId);
    final playerGlobalId = await _requireGlobalId('player', membership.playerId, playerIdentity?.globalId);

    final payload = <String, dynamic>{
      'app_id': membershipIdentity?.appId ?? syncId,
      if (membershipIdentity?.globalId != null) 'global_id': membershipIdentity!.globalId,
      'sync_id': syncId,
      'source_installation_id': installationId,
      'local_id': membership.id,
      'team_global_id': teamGlobalId,
      'player_global_id': playerGlobalId,
      'team_sync_id': teamSyncId,
      'player_sync_id': playerSyncId,
      'jersey_number': membership.jerseyNumber,
      'is_active': membership.isActive,
    };
    final row = await client.from('team_players').upsert(payload, onConflict: 'app_id').select('global_id').single();
    final globalId = row['global_id']?.toString();
    if (globalId != null && globalId.isNotEmpty) {
      await _entityIdentityRepository?.setGlobalId(entityType: 'team_player', localId: membership.id, globalId: globalId);
    }
  }

  Future<void> _adoptRemoteIdentity(
    SupabaseClient client,
    String table,
    String entityType,
    int localId,
    String syncId,
  ) async {
    final row = await client
        .from(table)
        .select('app_id, global_id')
        .eq('sync_id', syncId)
        .maybeSingle();
    final appId = row?['app_id']?.toString();
    final globalId = row?['global_id']?.toString();
    if (appId == null || appId.isEmpty || globalId == null || globalId.isEmpty) return;
    await _entityIdentityRepository?.adoptRemoteIdentity(
      entityType: entityType,
      localId: localId,
      appId: appId,
      globalId: globalId,
    );
  }

  Future<String> _requireGlobalId(String entityType, int localId, String? knownGlobalId) async {
    if (knownGlobalId != null && knownGlobalId.isNotEmpty) return knownGlobalId;
    final identity = await _entityIdentityRepository?.get(entityType, localId);
    final globalId = identity?.globalId;
    if (globalId == null || globalId.isEmpty) {
      throw StateError('Cannot sync relationship: $entityType $localId has no global_id. Upload the entity first.');
    }
    return globalId;
  }

  SupabaseClient _requireAuthenticatedClient() {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured. Sync remains offline.');
    if (client.auth.currentUser == null) throw StateError('Supabase sync requires an authenticated scorer.');
    return client;
  }
}
