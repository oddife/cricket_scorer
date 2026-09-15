import 'package:supabase_flutter/supabase_flutter.dart';

/// A read-only snapshot of synchronized match data.
///
/// The transport deliberately returns server rows rather than writing to
/// SQLite. Local ID mapping and reconciliation belong to the recovery layer.
class RemoteMatchSnapshot {
  const RemoteMatchSnapshot({
    required this.match,
    required this.innings,
    required this.ballEvents,
    required this.teams,
    required this.players,
    required this.teamPlayers,
  });

  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> innings;
  final List<Map<String, dynamic>> ballEvents;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> teamPlayers;
}

class SupabaseRecoveryTransport {
  const SupabaseRecoveryTransport(this._client);

  final SupabaseClient? _client;

  /// Returns matches visible to the current authenticated scorer.
  Future<List<Map<String, dynamic>>> listMatches() async {
    final client = _requireAuthenticatedClient();
    final rows = await client
        .from('matches')
        .select()
        .order('updated_at', ascending: false);
    return rows
        .map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row),
        )
        .toList(growable: false);
  }

  /// Pulls one complete server-side match snapshot in deterministic order.
  ///
  /// Reference data is read from the shared Team/Player catalog. The current
  /// backend schema stores innings and BallEvent player/team references as the
  /// originating device's local IDs, so the source installation ID is retained
  /// and used by the later reconciliation layer to resolve those references.
  Future<RemoteMatchSnapshot> pullMatch(String matchSyncId) async {
    final client = _requireAuthenticatedClient();

    final matchRow = await client
        .from('matches')
        .select()
        .eq('sync_id', matchSyncId)
        .maybeSingle();
    if (matchRow == null) {
      throw StateError('Synchronized match $matchSyncId was not found.');
    }

    final inningsRows = await client
        .from('innings')
        .select()
        .eq('match_sync_id', matchSyncId)
        .order('innings_number');

    final ballRows = await client
        .from('ball_events')
        .select()
        .eq('match_sync_id', matchSyncId)
        .order('innings_sync_id')
        .order('sequence_number');

    // Catalog tables are intentionally pulled as a coherent snapshot. The
    // reconciliation layer will retain only entities referenced by this match.
    final teamRows = await client.from('teams').select().order('sync_id');
    final playerRows = await client.from('players').select().order('sync_id');
    final membershipRows =
        await client.from('team_players').select().order('sync_id');

    return RemoteMatchSnapshot(
      match: Map<String, dynamic>.from(matchRow),
      innings: inningsRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      ballEvents: ballRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      teams: teamRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      players: playerRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      teamPlayers: membershipRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  SupabaseClient _requireAuthenticatedClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured. Recovery remains offline.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('Supabase recovery requires an authenticated scorer.');
    }
    return client;
  }
}
