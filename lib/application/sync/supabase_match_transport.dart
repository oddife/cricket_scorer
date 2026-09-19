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
    final appId = identity?.appId ?? syncId;
    final existing = await client.from('matches').select('sync_id, status, global_id').eq('app_id', appId).maybeSingle();
    final status = existing != null && existing['status'] == MatchStatus.completed.dbValue && match.status != MatchStatus.completed
        ? MatchStatus.completed.dbValue
        : match.status.dbValue;
    final tournamentGlobalId = tournamentSyncId == null ? null : await _resolveGlobalIdBySyncId('tournaments', tournamentSyncId);
    final payload = _matchPayload(match, installationId, syncId, tournamentSyncId, appId: appId, globalId: identity?.globalId, tournamentGlobalId: tournamentGlobalId, status: status);
    if (existing == null) {
      final inserted = await client.from('matches').insert(payload).select('global_id').single();
      final globalId = inserted['global_id'] as String?;
      if (globalId != null) await _entityIdentityRepository?.setGlobalId(entityType: 'match', localId: match.id, globalId: globalId);
    } else {
      await client.from('matches').update(payload).eq('app_id', appId);
      final globalId = existing['global_id'] as String?;
      if (globalId != null) await _entityIdentityRepository?.setGlobalId(entityType: 'match', localId: match.id, globalId: globalId);
    }
    await client.from('match_scorers').upsert(<String, dynamic>{'match_sync_id': syncId, 'user_id': client.auth.currentUser!.id}, onConflict: 'match_sync_id,user_id');
  }

  Future<void> uploadMatchTeams({
    required String matchSyncId,
    required List<MatchTeam> teams,
    required Future<String> Function(int teamId) teamSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    final matchGlobalId = await _resolveGlobalIdBySyncId('matches', matchSyncId);
    await client.from('match_teams').delete().eq('match_sync_id', matchSyncId);
    for (final team in teams) {
      final teamLegacyId = await teamSyncId(team.teamId);
      final teamIdentity = await _entityIdentityRepository?.ensure('team', team.teamId);
      final teamGlobalId = await _requireGlobalId('team', team.teamId, teamIdentity?.globalId, fallbackSyncId: teamLegacyId);
      final membershipAppId = '${matchGlobalId}_${teamGlobalId}_${team.slot.dbValue}';
      await client.from('match_teams').upsert(<String, dynamic>{
        'app_id': _uuidFromStablePair(matchGlobalId, teamGlobalId, team.slot.dbValue),
        'match_global_id': matchGlobalId,
        'team_global_id': teamGlobalId,
        'match_sync_id': matchSyncId,
        'team_sync_id': teamLegacyId,
        'slot': team.slot.dbValue,
      }, onConflict: 'app_id');
      membershipAppId;
    }
  }

  Future<void> uploadMatchPlayers({
    required String matchSyncId,
    required List<MatchPlayer> players,
    required Future<String> Function(int teamId) teamSyncId,
    required Future<String> Function(int playerId) playerSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    final matchGlobalId = await _resolveGlobalIdBySyncId('matches', matchSyncId);
    await client.from('match_players').delete().eq('match_sync_id', matchSyncId);
    for (final player in players) {
      final teamLegacyId = await teamSyncId(player.teamId);
      final playerLegacyId = await playerSyncId(player.playerId);
      final teamIdentity = await _entityIdentityRepository?.ensure('team', player.teamId);
      final playerIdentity = await _entityIdentityRepository?.ensure('player', player.playerId);
      final teamGlobalId = await _requireGlobalId('team', player.teamId, teamIdentity?.globalId, fallbackSyncId: teamLegacyId);
      final playerGlobalId = await _requireGlobalId('player', player.playerId, playerIdentity?.globalId, fallbackSyncId: playerLegacyId);
      await client.from('match_players').upsert(<String, dynamic>{
        'app_id': _uuidFromStablePair('${matchGlobalId}_${teamGlobalId}', playerGlobalId, player.battingOrder ?? -1),
        'match_global_id': matchGlobalId,
        'team_global_id': teamGlobalId,
        'player_global_id': playerGlobalId,
        'match_sync_id': matchSyncId,
        'team_sync_id': teamLegacyId,
        'player_sync_id': playerLegacyId,
        'is_playing': player.isPlaying,
        'batting_order': player.battingOrder,
      }, onConflict: 'app_id');
    }
  }

  Future<void> uploadInnings({required Innings innings, required String matchSyncId, required String syncId, required String installationId}) async {
    final client = _requireAuthenticatedClient();
    final identity = await _entityIdentityRepository?.ensure('innings', innings.id);
    final appId = identity?.appId ?? syncId;
    final matchGlobalId = await _resolveGlobalIdBySyncId('matches', matchSyncId);
    final payload = <String, dynamic>{
      'app_id': appId,
      if (identity?.globalId != null) 'global_id': identity!.globalId,
      'sync_id': syncId,
      'match_sync_id': matchSyncId,
      'match_global_id': matchGlobalId,
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
    final existing = await client.from('innings').select('global_id').eq('app_id', appId).maybeSingle();
    if (existing == null) {
      final inserted = await client.from('innings').insert(payload).select('global_id').single();
      final globalId = inserted['global_id'] as String?;
      if (globalId != null) await _entityIdentityRepository?.setGlobalId(entityType: 'innings', localId: innings.id, globalId: globalId);
    } else {
      await client.from('innings').update(payload).eq('app_id', appId);
      final globalId = existing['global_id'] as String?;
      if (globalId != null) await _entityIdentityRepository?.setGlobalId(entityType: 'innings', localId: innings.id, globalId: globalId);
    }
  }

  Map<String, dynamic> _matchPayload(Match match, String installationId, String syncId, String? tournamentSyncId, {required String appId, String? globalId, String? tournamentGlobalId, required int status}) => <String, dynamic>{
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
    'tournament_global_id': tournamentGlobalId,
  };

  Future<String> _resolveGlobalIdBySyncId(String table, String syncId) async {
    final row = await _requireAuthenticatedClient().from(table).select('global_id').eq('sync_id', syncId).maybeSingle();
    final globalId = row?['global_id']?.toString();
    if (globalId == null || globalId.isEmpty) throw StateError('Cannot sync relationship: $table record $syncId has no global_id on Supabase.');
    return globalId;
  }

  Future<String> _requireGlobalId(String entityType, int localId, String? knownGlobalId, {required String fallbackSyncId}) async {
    if (knownGlobalId != null && knownGlobalId.isNotEmpty) return knownGlobalId;
    final identity = await _entityIdentityRepository?.get(entityType, localId);
    final globalId = identity?.globalId;
    if (globalId != null && globalId.isNotEmpty) return globalId;
    return _resolveGlobalIdBySyncId(entityType == 'team' ? 'teams' : 'players', fallbackSyncId);
  }

  String _uuidFromStablePair(String first, String second, Object third) {
    final source = '$first:$second:$third';
    var hash = 0x811c9dc5;
    for (final codeUnit in source.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    final hex = hash.toRadixString(16).padLeft(8, '0');
    return '$hex-$hex-5-$hex-$hex$hex';
  }

  SupabaseClient _requireAuthenticatedClient() {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured. Sync remains offline.');
    if (client.auth.currentUser == null) throw StateError('Supabase sync requires an authenticated scorer.');
    return client;
  }
}
