import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/scoring/models/ball_event.dart';

class SupabaseBallEventTransport {
  const SupabaseBallEventTransport(this._client);

  final SupabaseClient? _client;

  Future<void> uploadBallEvent({
    required BallEvent event,
    required String installationId,
    required int matchId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    if (client.auth.currentSession == null) {
      throw StateError('Supabase authentication is required for sync.');
    }

    final matchSyncId = '$installationId:match:$matchId';
    final inningsSyncId = '$installationId:innings:${event.inningsId}';
    final payload = _payload(
      event: event,
      installationId: installationId,
      matchSyncId: matchSyncId,
      inningsSyncId: inningsSyncId,
    );

    try {
      await client.from('ball_events').insert(payload);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;

      final existing = await client
          .from('ball_events')
          .select()
          .eq('sync_id', eventSyncId(installationId, event.id))
          .maybeSingle();

      if (existing == null) rethrow;
      if (!_sameEvent(existing, payload)) {
        throw StateError(
          'Sync divergence for BallEvent ${event.id}: the server already '
          'contains a different payload for this sync ID.',
        );
      }
    }
  }

  static String eventSyncId(String installationId, int ballEventId) =>
      '$installationId:ball:$ballEventId';

  Map<String, dynamic> _payload({
    required BallEvent event,
    required String installationId,
    required String matchSyncId,
    required String inningsSyncId,
  }) {
    final wicket = event.wicket;
    return {
      'sync_id': eventSyncId(installationId, event.id),
      'source_installation_id': installationId,
      'local_id': event.id,
      'match_sync_id': matchSyncId,
      'innings_sync_id': inningsSyncId,
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

  bool _sameEvent(Map<String, dynamic> existing, Map<String, dynamic> expected) {
    const fields = [
      'sync_id',
      'source_installation_id',
      'local_id',
      'match_sync_id',
      'innings_sync_id',
      'sequence_number',
      'over_number',
      'legal_ball_number',
      'bowler_id',
      'striker_id',
      'non_striker_id',
      'delivery_type',
      'is_legal_ball',
      'batter_runs',
      'bye_runs',
      'leg_bye_runs',
      'wide_runs',
      'no_ball_runs',
      'total_runs',
      'wicket_type',
      'dismissed_player_id',
      'fielder_id',
      'run_out_end',
      'credited_to_bowler',
      'wicket_completed_runs',
      'wicket_crossed_before_wicket',
      'replacement_batter_id',
      'event_timestamp',
    ];

    for (final field in fields) {
      if (jsonEncode(existing[field]) != jsonEncode(expected[field])) {
        return false;
      }
    }
    return true;
  }
}
