import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/innings/models/innings.dart';
import '../../domain/matches/enums/match_status.dart';
import '../../domain/matches/enums/match_team_slot.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/matches/models/match.dart';
import '../../domain/matches/models/match_player.dart';
import '../../domain/matches/models/match_team.dart';
import '../../data/repositories/entity_identity_repository.dart';
import '../../data/repositories/sync_identity_repository.dart';

class SupabaseMatchTransport {
  const SupabaseMatchTransport(
    this._client, [
    this._entityIdentityRepository,
    this._syncIdentityRepository,
  ]);

  final SupabaseClient? _client;
  final EntityIdentityRepository? _entityIdentityRepository;
  final SyncIdentityRepository? _syncIdentityRepository;

  Future<void> uploadMatch({
    required Match match,
    required String syncId,
    required String installationId,
    String? tournamentSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    final remoteIdentity = await _adoptRemoteIdentity(
      client,
      'matches',
      'match',
      match.id,
      syncId,
    );
    final identity = await _entityIdentityRepository?.ensure('match', match.id);
    final appId = identity?.appId ?? syncId;
    final existing = await client
        .from('matches')
        .select(
          'sync_id, status, global_id, source_installation_id, local_id, is_published',
        )
        .eq('app_id', appId)
        .maybeSingle();
    final status = existing != null && existing['status'] == MatchStatus.completed.dbValue && match.status != MatchStatus.completed
        ? MatchStatus.completed.dbValue
        : match.status.dbValue;
    final tournamentGlobalId = tournamentSyncId == null
        ? null
        : await _resolveGlobalIdBySyncId('tournaments', tournamentSyncId);
    final tossWinnerTeamGlobalId = match.tossWinnerTeamId == null
        ? null
        : await _resolveLocalEntityGlobalId(
            'team',
            match.tossWinnerTeamId!,
          );
    final payload = _matchPayload(
      match,
      installationId,
      syncId,
      tournamentSyncId,
      appId: appId,
      globalId: identity?.globalId,
      tournamentGlobalId: tournamentGlobalId,
      tossWinnerTeamGlobalId: tossWinnerTeamGlobalId,
      status: status,
    );
    // A newly inserted match stays private until its team/player assignments
    // and innings have been uploaded. Existing published matches remain
    // published; an incomplete unpublished row stays private across retries.
    payload['is_published'] = existing?['is_published'] == true;
    // source_installation_id/local_id are legacy origin pointers used to
    // resolve toss and innings player/team IDs. They must remain stable when
    // another device edits the same synchronized match.
    final origin = existing ?? remoteIdentity;
    final originInstallationId =
        origin?['source_installation_id']?.toString();
    final originLocalId = origin?['local_id'];
    if (originInstallationId != null && originInstallationId.isNotEmpty) {
      payload['source_installation_id'] = originInstallationId;
    }
    if (originLocalId is int) payload['local_id'] = originLocalId;
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
      // The match row must exist before a scorer can claim it.
      await _claimMatch(client, syncId);
    } else {
      // The RLS update policy only allows a user who is already a scorer.
      // Claim the existing published match before attempting to update it.
      await _claimMatch(client, syncId);
      final sourceInstallationId =
          existing['source_installation_id']?.toString();
      final ownsMatchMetadata = sourceInstallationId == null ||
          sourceInstallationId.isEmpty ||
          sourceInstallationId == installationId;
      if (ownsMatchMetadata) {
        await client.from('matches').update(payload).eq('app_id', appId);
      } else if (match.status == MatchStatus.completed &&
          existing['status'] != MatchStatus.completed.dbValue) {
        // A secondary client may advance match completion, but must not push
        // stale setup fields back over the originating device's metadata.
        await client
            .from('matches')
            .update(<String, dynamic>{
              'status': MatchStatus.completed.dbValue,
            })
            .eq('app_id', appId);
      }
      final globalId = existing['global_id'] as String?;
      if (globalId != null) {
        await _entityIdentityRepository?.setGlobalId(
          entityType: 'match',
          localId: match.id,
          globalId: globalId,
        );
      }
    }
  }

  /// Makes a match visible to other installations after setup uploads finish.
  ///
  /// The source installation owns publication. A match is left unpublished
  /// while required team/player assignments are incomplete, so another client
  /// cannot download a half-written snapshot during the multiple REST writes.
  Future<void> publishMatch({
    required String matchSyncId,
    required String installationId,
  }) async {
    final client = _requireAuthenticatedClient();
    final matchRow = await client
        .from('matches')
        .select('source_installation_id, is_published')
        .eq('sync_id', matchSyncId)
        .maybeSingle();
    if (matchRow == null || matchRow['is_published'] == true) return;

    final sourceInstallationId =
        matchRow['source_installation_id']?.toString();
    if (sourceInstallationId != installationId) return;

    final teamRows = await client
        .from('match_teams')
        .select('slot')
        .eq('match_sync_id', matchSyncId);
    final slots = teamRows
        .map((row) => row['slot'])
        .whereType<int>()
        .toSet();
    if (slots.length < 2) return;

    final playerRows = await client
        .from('match_players')
        .select('player_sync_id, player_global_id')
        .eq('match_sync_id', matchSyncId);
    final hasPlayerAssignment = playerRows.any((row) {
      final syncId = row['player_sync_id']?.toString();
      final globalId = row['player_global_id']?.toString();
      return (syncId != null && syncId.isNotEmpty) ||
          (globalId != null && globalId.isNotEmpty);
    });
    if (!hasPlayerAssignment) return;

    await client
        .from('matches')
        .update(<String, dynamic>{'is_published': true})
        .eq('sync_id', matchSyncId)
        .eq('source_installation_id', installationId);
  }

  Future<void> uploadMatchTeams({
    required String matchSyncId,
    required String installationId,
    required List<MatchTeam> teams,
    required Future<String> Function(int teamId) teamSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    final matchRow = await client
        .from('matches')
        .select('source_installation_id')
        .eq('sync_id', matchSyncId)
        .maybeSingle();
    final sourceInstallationId =
        matchRow?['source_installation_id']?.toString();
    if (sourceInstallationId != null &&
        sourceInstallationId.isNotEmpty &&
        sourceInstallationId != installationId) {
      return;
    }
    final matchGlobalId = await _resolveGlobalIdBySyncId('matches', matchSyncId);
    // The originating installation owns the two match-team slots. Other
    // clients may read them, but must not replace them from a stale local copy.
    for (final team in teams) {
      final teamLegacyId = await teamSyncId(team.teamId);
      final teamIdentity = await _entityIdentityRepository?.ensure('team', team.teamId);
      final teamGlobalId = await _requireGlobalId('team', team.teamId, teamIdentity?.globalId, fallbackSyncId: teamLegacyId);
      await client.from('match_teams').upsert(<String, dynamic>{
        'match_global_id': matchGlobalId,
        'team_global_id': teamGlobalId,
        'match_sync_id': matchSyncId,
        'team_sync_id': teamLegacyId,
        'slot': team.slot.dbValue,
      }, onConflict: 'match_sync_id,slot');
    }
  }

  Future<void> uploadMatchPlayers({
    required String matchSyncId,
    required String installationId,
    required List<MatchPlayer> players,
    required Future<String> Function(int teamId) teamSyncId,
    required Future<String> Function(int playerId) playerSyncId,
  }) async {
    final client = _requireAuthenticatedClient();
    final matchRow = await client
        .from('matches')
        .select('source_installation_id')
        .eq('sync_id', matchSyncId)
        .maybeSingle();
    final sourceInstallationId =
        matchRow?['source_installation_id']?.toString();
    final ownsMatchMetadata = sourceInstallationId == null ||
        sourceInstallationId.isEmpty ||
        sourceInstallationId == installationId;
    final matchGlobalId = await _resolveGlobalIdBySyncId('matches', matchSyncId);
    // Merge participant rows by player. A stale local roster must not delete
    // players added during live scoring on another client. Only the originating
    // device may change existing participants; other devices may add missing
    // participants without resetting the remote is_playing/order values.
    for (final player in players) {
      final teamLegacyId = await teamSyncId(player.teamId);
      final playerLegacyId = await playerSyncId(player.playerId);
      final teamIdentity = await _entityIdentityRepository?.ensure('team', player.teamId);
      final playerIdentity = await _entityIdentityRepository?.ensure('player', player.playerId);
      final teamGlobalId = await _requireGlobalId('team', player.teamId, teamIdentity?.globalId, fallbackSyncId: teamLegacyId);
      final playerGlobalId = await _requireGlobalId('player', player.playerId, playerIdentity?.globalId, fallbackSyncId: playerLegacyId);
      final payload = <String, dynamic>{
        'match_global_id': matchGlobalId,
        'team_global_id': teamGlobalId,
        'player_global_id': playerGlobalId,
        'match_sync_id': matchSyncId,
        'team_sync_id': teamLegacyId,
        'player_sync_id': playerLegacyId,
        'is_playing': player.isPlaying,
        'batting_order': player.battingOrder,
      };
      if (ownsMatchMetadata) {
        await client.from('match_players').upsert(
          payload,
          onConflict: 'match_sync_id,player_sync_id',
        );
      } else {
        final existingParticipant = await client
            .from('match_players')
            .select('player_sync_id')
            .eq('match_sync_id', matchSyncId)
            .eq('player_sync_id', playerLegacyId)
            .maybeSingle();
        if (existingParticipant == null) {
          await client.from('match_players').insert(payload);
        }
      }
    }
  }

  Future<void> uploadInnings({required Innings innings, required String matchSyncId, required String syncId, required String installationId}) async {
    final client = _requireAuthenticatedClient();
    final remoteIdentity = await _adoptRemoteIdentity(
      client,
      'innings',
      'innings',
      innings.id,
      syncId,
    );
    final identity = await _entityIdentityRepository?.ensure('innings', innings.id);
    final appId = identity?.appId ?? syncId;
    final matchGlobalId = await _resolveGlobalIdBySyncId('matches', matchSyncId);
    final battingTeamGlobalId = await _resolveLocalEntityGlobalId(
      'team',
      innings.battingTeamId,
    );
    final bowlingTeamGlobalId = await _resolveLocalEntityGlobalId(
      'team',
      innings.bowlingTeamId,
    );
    final openingStrikerGlobalId = await _resolveLocalEntityGlobalId(
      'player',
      innings.openingStrikerId,
    );
    final openingNonStrikerGlobalId = await _resolveLocalEntityGlobalId(
      'player',
      innings.openingNonStrikerId,
    );
    final openingBowlerGlobalId = await _resolveLocalEntityGlobalId(
      'player',
      innings.openingBowlerId,
    );
    final activeTwoBowlerOneGlobalId =
        innings.activeTwoBowlerOneId == null
            ? null
            : await _resolveLocalEntityGlobalId(
                'player',
                innings.activeTwoBowlerOneId!,
              );
    final activeTwoBowlerTwoGlobalId =
        innings.activeTwoBowlerTwoId == null
            ? null
            : await _resolveLocalEntityGlobalId(
                'player',
                innings.activeTwoBowlerTwoId!,
              );
    final payload = <String, dynamic>{
      'app_id': appId,
      if (identity?.globalId != null) 'global_id': identity!.globalId,
      'sync_id': syncId,
      'match_sync_id': matchSyncId,
      'match_global_id': matchGlobalId,
      'batting_team_global_id': battingTeamGlobalId,
      'bowling_team_global_id': bowlingTeamGlobalId,
      'opening_striker_global_id': openingStrikerGlobalId,
      'opening_non_striker_global_id': openingNonStrikerGlobalId,
      'opening_bowler_global_id': openingBowlerGlobalId,
      'active_two_bowler_one_global_id': activeTwoBowlerOneGlobalId,
      'active_two_bowler_two_global_id': activeTwoBowlerTwoGlobalId,
      'source_installation_id':
          remoteIdentity?['source_installation_id']?.toString() ??
              installationId,
      'local_id': remoteIdentity?['local_id'] is int
          ? remoteIdentity!['local_id'] as int
          : innings.id,
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
        .select('global_id, source_installation_id, local_id, status')
        .eq('app_id', appId)
        .maybeSingle();
    final origin = existing ?? remoteIdentity;
    final originInstallationId =
        origin?['source_installation_id']?.toString();
    final originLocalId = origin?['local_id'];
    if (originInstallationId != null && originInstallationId.isNotEmpty) {
      payload['source_installation_id'] = originInstallationId;
    }
    if (originLocalId is int) payload['local_id'] = originLocalId;

    final remoteStatus = existing?['status']?.toString();
    final localStatus = innings.status.name;
    final ownsInningsMetadata = originInstallationId == null ||
        originInstallationId.isEmpty ||
        originInstallationId == installationId;

    if (existing != null && !ownsInningsMetadata) {
      // Secondary clients may advance an innings state, but must not replace
      // the originating device's setup/opening-player metadata with a stale
      // local snapshot.
      if (_inningsStatusRank(localStatus) >
          _inningsStatusRank(remoteStatus ?? '')) {
        final statusUpdate = <String, dynamic>{'status': localStatus};
        if (localStatus == 'live' && innings.startedAt != null) {
          statusUpdate['started_at'] =
              innings.startedAt!.toUtc().toIso8601String();
        }
        if ((localStatus == 'completed' || localStatus == 'ended') &&
            innings.completedAt != null) {
          statusUpdate['completed_at'] =
              innings.completedAt!.toUtc().toIso8601String();
        }
        await client
            .from('innings')
            .update(statusUpdate)
            .eq('app_id', appId);
      }
      final globalId = existing['global_id'] as String?;
      if (globalId != null) {
        await _entityIdentityRepository?.setGlobalId(
          entityType: 'innings',
          localId: innings.id,
          globalId: globalId,
        );
      }
      return;
    }

    if ((remoteStatus == 'completed' || remoteStatus == 'ended') &&
        localStatus != 'completed' &&
        localStatus != 'ended') {
      payload['status'] = remoteStatus;
    } else if (remoteStatus == 'live' && localStatus == 'setup') {
      payload['status'] = 'live';
    }

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

  Map<String, dynamic> _matchPayload(
    Match match,
    String installationId,
    String syncId,
    String? tournamentSyncId, {
    required String appId,
    String? globalId,
    String? tournamentGlobalId,
    String? tossWinnerTeamGlobalId,
    required int status,
  }) => <String, dynamic>{
    'app_id': appId,
    'global_id': ?globalId,
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
    'bowler_colour_coding_enabled': match.bowlerColourCodingEnabled,
    'toss_winner_team_id': match.tossWinnerTeamId,
    'toss_winner_team_global_id': tossWinnerTeamGlobalId,
    'toss_decision': match.tossDecision?.dbValue,
    'status': status,
    'tournament_sync_id': tournamentSyncId,
    'tournament_global_id': tournamentGlobalId,
  };

  Future<Map<String, dynamic>?> _adoptRemoteIdentity(
    SupabaseClient client,
    String table,
    String entityType,
    int localId,
    String syncId,
  ) async {
    final row = await client
        .from(table)
        .select('app_id, global_id, source_installation_id, local_id')
        .eq('sync_id', syncId)
        .maybeSingle();
    if (row == null) return null;
    final appId = row['app_id']?.toString();
    final globalId = row['global_id']?.toString();
    if (appId != null &&
        appId.isNotEmpty &&
        globalId != null &&
        globalId.isNotEmpty) {
      await _entityIdentityRepository?.adoptRemoteIdentity(
        entityType: entityType,
        localId: localId,
        appId: appId,
        globalId: globalId,
      );
    }
    return Map<String, dynamic>.from(row);
  }

  Future<void> _claimMatch(SupabaseClient client, String syncId) async {
    await client.from('match_scorers').upsert(
      <String, dynamic>{
        'match_sync_id': syncId,
        'user_id': client.auth.currentUser!.id,
      },
      onConflict: 'match_sync_id,user_id',
    );
  }

  int _inningsStatusRank(String status) => switch (status) {
        'setup' => 0,
        'live' => 1,
        'completed' || 'ended' => 2,
        _ => -1,
      };

  Future<String?> _resolveLocalEntityGlobalId(
    String entityType,
    int localId,
  ) async {
    final identity =
        await _entityIdentityRepository?.ensure(entityType, localId);
    final knownGlobalId = identity?.globalId;
    if (knownGlobalId != null && knownGlobalId.isNotEmpty) {
      return knownGlobalId;
    }

    final syncRepository = _syncIdentityRepository;
    if (syncRepository == null) {
      // Keep older unit-test/manual transport construction compatible. The
      // application provider always supplies the sync identity repository.
      return null;
    }
    final syncId = entityType == 'team'
        ? await syncRepository.ensureTeamSyncId(localId)
        : await syncRepository.ensurePlayerSyncId(localId);
    final table = entityType == 'team' ? 'teams' : 'players';
    final row = await _requireAuthenticatedClient()
        .from(table)
        .select('global_id')
        .eq('sync_id', syncId)
        .maybeSingle();
    final globalId = row?['global_id']?.toString();
    if (globalId == null || globalId.isEmpty) {
      throw StateError(
        'Cannot sync $entityType reference $localId: $syncId has no '
        'shared global ID. Sync the catalog first.',
      );
    }
    await _entityIdentityRepository?.setGlobalId(
      entityType: entityType,
      localId: localId,
      globalId: globalId,
    );
    return globalId;
  }

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

  SupabaseClient _requireAuthenticatedClient() {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured. Sync remains offline.');
    if (client.auth.currentUser == null) throw StateError('Supabase sync requires an authenticated scorer.');
    return client;
  }
}
