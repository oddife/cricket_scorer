import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/innings/models/innings.dart';
import '../../domain/matches/models/match.dart';

class SupabaseMatchTransport {
  const SupabaseMatchTransport(this._client);

  final SupabaseClient? _client;

  Future<void> uploadMatch({
    required Match match,
    required String installationId,
  }) async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Supabase sync requires an authenticated scorer.');
    }

    final syncId = matchSyncId(
      installationId: installationId,
      matchId: match.id,
    );
    final payload = _matchPayload(match, installationId, syncId);

    final existing = await client
        .from('matches')
        .select('sync_id')
        .eq('sync_id', syncId)
        .maybeSingle();

    if (existing == null) {
      await client.from('matches').insert(payload);
    }

    await client.from('match_scorers').upsert(
      <String, dynamic>{
        'match_sync_id': syncId,
        'user_id': user.id,
      },
      onConflict: 'match_sync_id,user_id',
    );

    await client.from('matches').update(payload).eq('sync_id', syncId);
  }

  Future<void> uploadInnings({
    required Innings innings,
    required Match match,
    required String installationId,
  }) async {
    final client = _requireClient();
    if (client.auth.currentUser == null) {
      throw StateError('Supabase sync requires an authenticated scorer.');
    }

    final matchSyncIdValue = matchSyncId(
      installationId: installationId,
      matchId: match.id,
    );
    final syncId = inningsSyncId(
      installationId: installationId,
      inningsId: innings.id,
    );
    final payload = <String, dynamic>{
      'sync_id': syncId,
      'match_sync_id': matchSyncIdValue,
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
      'started_at': innings.startedAt?.toIso8601String(),
      'completed_at': innings.completedAt?.toIso8601String(),
    };

    final existing = await client
        .from('innings')
        .select('sync_id')
        .eq('sync_id', syncId)
        .maybeSingle();

    if (existing == null) {
      await client.from('innings').insert(payload);
    } else {
      await client.from('innings').update(payload).eq('sync_id', syncId);
    }
  }

  static String matchSyncId({
    required String installationId,
    required int matchId,
  }) => '$installationId:match:$matchId';

  static String inningsSyncId({
    required String installationId,
    required int inningsId,
  }) => '$installationId:innings:$inningsId';

  Map<String, dynamic> _matchPayload(
    Match match,
    String installationId,
    String syncId,
  ) {
    return <String, dynamic>{
      'sync_id': syncId,
      'source_installation_id': installationId,
      'local_id': match.id,
      'name': match.name,
      'date': match.date.toIso8601String(),
      'venue': match.venue,
      'innings_count': match.inningsCount,
      'overs_per_innings': match.oversPerInnings,
      'balls_per_over': match.ballsPerOver,
      'players_per_team': match.playersPerTeam,
      'two_bowler_mode': match.twoBowlerMode,
      'toss_winner_team_id': match.tossWinnerTeamId,
      'toss_decision': match.tossDecision?.dbValue,
      'status': match.status.dbValue,
    };
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured. Sync remains offline.');
    }
    return client;
  }
}
