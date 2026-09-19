import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/innings/models/innings.dart';
import '../../domain/matches/enums/match_status.dart';
import '../../domain/matches/enums/match_team_slot.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/matches/models/match.dart';
import '../../domain/matches/models/match_player.dart';
import '../../domain/matches/models/match_team.dart';
import '../../data/repositories/entity_identity_repository.dart';

class SupabaseMatchTransport {
  const SupabaseMatchTransport(this._client, [this._entityIdentityRepository]);

  final SupabaseClient? _client;
  final EntityIdentityRepository? _entityIdentityRepository;

  Future<void> uploadMatch({
    required Match match,
    required String syncId,
    required String installationId,
    String? tournamentSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    final identity = await _entityIdentityRepository?.ensure('match', match.id);
    final existing = await client
        .from('matches')
        .select('sync_id, status, global_id')
        .eq('app_id', identity?.appId ?? syncId)
        .maybeSingle();

    final status = existing != null &&
            existing['status'] == MatchStatus.completed.dbValue &&
            match.status != MatchStatus.completed
        ? MatchStatus.completed.dbValue
        : match.status.dbValue;

    final payload = _matchPayload(
      match,
      installationId,
      syncId,
      tournamentSyncId,
      appId: identity?.appId ?? syncId,
      globalId: identity?.globalId,
      status: status,
    );
    if (existing == null) {
      final inserted = await client.from('matches').insert(payload).select('global_id').single();
      final globalId = inserted['global_id'] as String?;
      if (globalId != null) {
        await _entityIdentityRepository?.setGlobalId(
          entityType: 'match',
          localId: match.id,
          globalId: globalId,
        );
      }
    } else {
      await client.from('matches').update(payload).eq('app_id', identity?.appId ?? syncId);
      final globalId = existing['global_id'] as String?;
      if (globalId != null) {
        await _entityIdentityRepository?.setGlobalId(
          entityType: 'match',
          localId: match.id,
          globalId: globalId,
        );
      }
    }
    await client.from('match_scorers').upsert(
      <String, dynamic>{
        'match_sync_id': syncId,
        'user_id': client.auth.currentUser!.id,
      },
      onConflict: 'match_sync_id,user_id',
    );
  }

  Future<void> uploadMatchTeams({
    required String matchSyncId,
    required List<MatchTeam> teams,
    required Future<String> Function(int teamId) teamSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    await client.from('match_teams').delete().eq('match_sync_id', matchSyncId);
    for (final team in teams) {
      await client.from('match_teams').insert(
        <String, dynamic>{
          'match_sync_id': matchSyncId,
          'slot': team.slot.dbValue,
          'team_sync_id': await teamSyncId(team.teamId),
        },
      );
    }
  }

  Future<void> uploadMatchPlayers({
    required String matchSyncId,
    required List<MatchPlayer> players,
    required Future<String> Function(int teamId) teamSyncId,
    required Future<String> Function(int playerId) playerSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    await client.from('match_players').delete().eq('match_sync_id', matchSyncId);
    for (final player in players) {
      await client.from('match_players').insert(
        <String, dynamic>{
          'match_sync_id': matchSyncId,
          'team_sync_id': await teamSyncId(player.teamId),
          'player_sync_id': await playerSyncId(player.playerId),
          'is_playing': player.isPlaying,
          'batting_order': player.battingOrder,
        },
      );
    }
  }

  Future<void> uploadInnings({
    required Innings innings,
    required String matchSyncId,
    required String syncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    final identity = await _entityIdentityRepository?.ensure('innings', innings.id);
    final payload = <String, dynamic>{
      'app_id': identity?.appId ?? syncId,
      if (identity?.globalId != null) 'global_id': identity!.globalId,
      'sync_id': syncId,
      'match_sync_id': matchSyncId,
      'source_installation_id': installationId,
      'local_id': innings.id,
      'innings_number': innings.inningsNumber,
      'batting_team_id': innings.battingTeamId,
      'bowling_team_id': innings.bowlingTeamId,
      'opening_striker_id': innings.openingStrikerId,
      'opening_non_striker_id': innings.openingNonStrikerId,
      'opening_bowler_id': innings.openingBowlerId,
      'overs_per_innings': innings.oversPerInnings,
      'balls_per_over': innings.ballsPerOver,
      'two_bowler_mode': innings.twoBowlerMode,
      'status': innings.status.name,
      'started_at': innings.startedAt?.toUtc().toIso8601String(),
      'completed_at': innings.completedAt?.toUtc().toIso8601String(),
    };
    final existing = await client
        .from('innings')
        .select('global_id')
        .eq('app_id', identity?.appId ?? syncId)
        .maybeSingle();
    if (existing == null) {
      final inserted = await client.from('innings').insert(payload).select('global_id').single();
      final globalId = inserted['global_id'] as String?;
      if (globalId != null) {
        await _entityIdentityRepository?.setGlobalId(entityType: 'innings', localId: innings.id, globalId: globalId);
      }
    } else {
      await client.from('innings').update(payload).eq('app_id', identity?.appId ?? syncId);
      final globalId = existing['global_id'] as String?;
      if (globalId != null) {
        await _entityIdentityRepository?.setGlobalId(entityType: 'innings', localId: innings.id, globalId: globalId);
      }
    }
  }

  Map<String, dynamic> _matchPayload(
    Match match,
    String installationId,
    String syncId,
    String? tournamentSyncId, {
    required String appId,
    String? globalId,
    required int status,
  }) {
    return <String, dynamic>{
      'app_id': appId,
      if (globalId != null) 'global_id': globalId,
      'sync_id': syncId,
      'source_installation_id': installationId,
      'local_id': match.id,
      'name': match.name,
      'date': match.date.toUtc().toIso8601String(),
      'is_published': true,
      'venue': match.venue,
      'innings_count': match.inningsCount,
      'overs_per_innings': match.oversPerInnings,
      'balls_per_over': match.ballsPerOver,
      'players_per_team': match.playersPerTeam,
      'two_bowler_mode': match.twoBowlerMode,
      'toss_winner_team_id': match.tossWinnerTeamId,
      'toss_decision': match.tossDecision?.dbValue,
      'status': status,
      'tournament_sync_id': tournamentSyncId,
    };
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
