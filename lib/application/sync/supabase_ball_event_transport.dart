import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/entity_identity_repository.dart';
import '../../domain/scoring/models/ball_event.dart';

class SupabaseBallEventTransport {
  const SupabaseBallEventTransport(this._client, [this._entityIdentityRepository]);

  final SupabaseClient? _client;
  final EntityIdentityRepository? _entityIdentityRepository;

  Future<void> uploadBallEvent({required BallEvent event, required String syncId, required String matchSyncId, required String inningsSyncId, required String installationId}) async {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured.');
    if (client.auth.currentSession == null) throw StateError('Supabase authentication is required for sync.');
    final identity = await _entityIdentityRepository?.ensure('ball_event', event.id);
    final appId = identity?.appId ?? syncId;
    final matchGlobalId = await _resolveGlobalIdBySyncId('matches', matchSyncId);
    final inningsGlobalId = await _resolveGlobalIdBySyncId('innings', inningsSyncId);
    final payload = _payload(event: event, installationId: installationId, syncId: syncId, matchSyncId: matchSyncId, inningsSyncId: inningsSyncId, matchGlobalId: matchGlobalId, inningsGlobalId: inningsGlobalId, appId: appId, globalId: identity?.globalId);
    try {
      final inserted = await client.from('ball_events').insert(payload).select('global_id').single();
      final globalId = inserted['global_id'] as String?;
      if (globalId != null) await _entityIdentityRepository?.setGlobalId(entityType: 'ball_event', localId: event.id, globalId: globalId);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final existing = await client.from('ball_events').select().eq('app_id', appId).maybeSingle();
      if (existing == null) rethrow;
      if (!_sameEvent(existing, payload)) throw StateError('Sync divergence for BallEvent ${event.id}: the server already contains a different payload for this app ID.');
      final globalId = existing['global_id'] as String?;
      if (globalId != null) await _entityIdentityRepository?.setGlobalId(entityType: 'ball_event', localId: event.id, globalId: globalId);
    }
  }

  Map<String, dynamic> _payload({required BallEvent event, required String installationId, required String syncId, required String matchSyncId, required String inningsSyncId, required String matchGlobalId, required String inningsGlobalId, required String appId, String? globalId}) {
    final wicket = event.wicket;
    return {
      'app_id': appId,
      'global_id': ?globalId,
      'sync_id': syncId,
      'source_installation_id': installationId,
      'local_id': event.id,
      'match_sync_id': matchSyncId,
      'innings_sync_id': inningsSyncId,
      'match_global_id': matchGlobalId,
      'innings_global_id': inningsGlobalId,
      'sequence_number': event.sequenceNumber,
      'over_number': event.overNumber,
      'legal_ball_number': event.legalBallNumber,
      'bowler_id': event.bowlerId,
      'striker_id': event.strikerId,
      'non_striker_id': event.nonStrikerId,
      'delivery_type': event.deliveryType.index,
      'is_legal_ball': event.isLegalBall,
      'batter_runs': event.batterRuns,
      'bye_runs': event.byeRuns,
      'leg_bye_runs': event.legByeRuns,
      'wide_runs': event.wideRuns,
      'no_ball_runs': event.noBallRuns,
      'total_runs': event.totalRuns,
      'wicket_type': wicket?.type.index,
      'dismissed_player_id': wicket?.dismissedPlayerId,
      'fielder_id': wicket?.fielderId,
      'run_out_end': wicket?.runOutEnd?.index,
      'credited_to_bowler': wicket?.creditedToBowler,
      'wicket_completed_runs': wicket?.completedRuns ?? 0,
      'wicket_crossed_before_wicket': wicket?.crossedBeforeWicket ?? false,
      'replacement_batter_id': wicket?.replacementBatterId,
      'event_timestamp': event.timestamp.toUtc().toIso8601String(),
    };
  }

  Future<String> _resolveGlobalIdBySyncId(String table, String syncId) async {
    final row = await _requireAuthenticatedClient().from(table).select('global_id').eq('sync_id', syncId).maybeSingle();
    final globalId = row?['global_id']?.toString();
    if (globalId == null || globalId.isEmpty) throw StateError('Cannot sync relationship: $table record $syncId has no global_id on Supabase.');
    return globalId;
  }

  bool _sameEvent(Map<String, dynamic> existing, Map<String, dynamic> expected) {
    const fields = ['app_id', 'source_installation_id', 'local_id', 'match_sync_id', 'innings_sync_id', 'match_global_id', 'innings_global_id', 'sequence_number', 'over_number', 'legal_ball_number', 'bowler_id', 'striker_id', 'non_striker_id', 'delivery_type', 'is_legal_ball', 'batter_runs', 'bye_runs', 'leg_bye_runs', 'wide_runs', 'no_ball_runs', 'total_runs', 'wicket_type', 'dismissed_player_id', 'fielder_id', 'run_out_end', 'credited_to_bowler', 'wicket_completed_runs', 'wicket_crossed_before_wicket', 'replacement_batter_id', 'event_timestamp'];
    for (final field in fields) {
      if (jsonEncode(existing[field]) != jsonEncode(expected[field])) return false;
    }
    return true;
  }

  SupabaseClient _requireAuthenticatedClient() {
    final client = _client;
    if (client == null) throw StateError('Supabase is not configured. Sync remains offline.');
    if (client.auth.currentUser == null) throw StateError('Supabase sync requires an authenticated scorer.');
    return client;
  }
}
