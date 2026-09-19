import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/tournaments/enums/tournament_type.dart';
import '../../domain/tournaments/models/tournament.dart';
import '../../domain/tournaments/models/tournament_points_rules.dart';
import '../../domain/teams/models/team.dart';
import '../../data/repositories/entity_identity_repository.dart';

class SupabaseTournamentTransport {
  const SupabaseTournamentTransport(this._client, [this._entityIdentityRepository]);

  final SupabaseClient? _client;
  final EntityIdentityRepository? _entityIdentityRepository;

  Future<void> uploadTournament({required Tournament tournament, required String syncId, required String installationId}) async {
    final client = _requireAuthenticatedClient();
    final identity = await _entityIdentityRepository?.ensure('tournament', tournament.id);
    final appId = identity?.appId ?? syncId;
    final payload = <String, dynamic>{
      'app_id': appId,
      if (identity?.globalId != null) 'global_id': identity!.globalId,
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
    };
    final existing = await client.from('tournaments').select('global_id').eq('app_id', appId).maybeSingle();
    if (existing == null) {
      final inserted = await client.from('tournaments').insert(payload).select('global_id').single();
      final globalId = inserted['global_id'] as String?;
      if (globalId != null) await _entityIdentityRepository?.setGlobalId(entityType: 'tournament', localId: tournament.id, globalId: globalId);
    } else {
      await client.from('tournaments').update(payload).eq('app_id', appId);
      final globalId = existing['global_id'] as String?;
      if (globalId != null) await _entityIdentityRepository?.setGlobalId(entityType: 'tournament', localId: tournament.id, globalId: globalId);
    }
  }

  Future<void> uploadTournamentTeams({required String tournamentSyncId, required List<Team> teams, required Future<String> Function(int teamId) teamSyncId}) async {
    final client = _requireAuthenticatedClient();
    final tournamentRow = await client.from('tournaments').select('global_id').eq('sync_id', tournamentSyncId).maybeSingle();
    final tournamentGlobalId = tournamentRow?['global_id']?.toString();
    if (tournamentGlobalId == null || tournamentGlobalId.isEmpty) {
      throw StateError('Cannot sync tournament teams: tournament $tournamentSyncId has no global_id on Supabase.');
    }

    await client.from('tournament_teams').delete().eq('tournament_global_id', tournamentGlobalId);

    for (final team in teams) {
      final legacyTeamSyncId = await teamSyncId(team.id);
      final teamRow = await client.from('teams').select('global_id').eq('sync_id', legacyTeamSyncId).maybeSingle();
      final teamGlobalId = teamRow?['global_id']?.toString();
      if (teamGlobalId == null || teamGlobalId.isEmpty) {
        throw StateError('Cannot sync tournament team: team $legacyTeamSyncId has no global_id on Supabase.');
      }

      await client.from('tournament_teams').upsert({
        'tournament_global_id': tournamentGlobalId,
        'team_global_id': teamGlobalId,
        'tournament_sync_id': tournamentSyncId,
        'team_sync_id': legacyTeamSyncId,
      }, onConflict: 'tournament_global_id,team_global_id');
    }
  }

  Future<void> uploadPointsRules({required TournamentPointsRules rules, required String tournamentSyncId}) async {
    final client = _requireAuthenticatedClient();
    await client.from('tournament_points_rules').upsert({'tournament_sync_id': tournamentSyncId, 'win_points': rules.winPoints, 'tie_points': rules.tiePoints, 'no_result_points': rules.noResultPoints, 'loss_points': rules.lossPoints, 'updated_at': DateTime.now().toUtc().toIso8601String()}, onConflict: 'tournament_sync_id');
  }

  SupabaseClient _requireAuthenticatedClient() {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured. Sync remains offline.');
    if (client.auth.currentUser == null) throw StateError('Supabase sync requires an authenticated scorer.');
    return client;
  }
}
