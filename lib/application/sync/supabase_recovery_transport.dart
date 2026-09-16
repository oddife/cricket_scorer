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
    required this.matchTeams,
    required this.matchPlayers,
    this.tournament,
    this.tournamentTeams = const [],
    this.tournamentPointsRules,
  });

  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> innings;
  final List<Map<String, dynamic>> ballEvents;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> teamPlayers;
  final List<Map<String, dynamic>> matchTeams;
  final List<Map<String, dynamic>> matchPlayers;
  final Map<String, dynamic>? tournament;
  final List<Map<String, dynamic>> tournamentTeams;
  final Map<String, dynamic>? tournamentPointsRules;
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
  /// Reference data is read from the shared Team/Player catalog. Match-level
  /// team/player assignments are also included so recovery can reconstruct
  /// MatchTeams and MatchPlayers without guessing from ball events.
  ///
  /// Tournament metadata is included when the match belongs to a tournament,
  /// so recovery does not silently turn a tournament match into a normal match.
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

    final matchTeamRows = await client
        .from('match_teams')
        .select()
        .eq('match_sync_id', matchSyncId)
        .order('slot');

    final matchPlayerRows = await client
        .from('match_players')
        .select()
        .eq('match_sync_id', matchSyncId)
        .order('team_sync_id')
        .order('batting_order');

    // Catalog tables are intentionally pulled as a coherent snapshot. The
    // reconciliation layer will retain only entities referenced by this match.
    final teamRows = await client.from('teams').select().order('sync_id');
    final playerRows = await client.from('players').select().order('sync_id');
    final membershipRows =
        await client.from('team_players').select().order('sync_id');

    Map<String, dynamic>? tournamentRow;
    List<Map<String, dynamic>> tournamentTeamRows = const [];
    Map<String, dynamic>? pointsRulesRow;

    final tournamentSyncId = matchRow['tournament_sync_id']?.toString();
    if (tournamentSyncId != null && tournamentSyncId.isNotEmpty) {
      final row = await client
          .from('tournaments')
          .select()
          .eq('sync_id', tournamentSyncId)
          .maybeSingle();
      if (row == null) {
        throw StateError(
          'Synchronized tournament $tournamentSyncId referenced by '
          'match $matchSyncId was not found.',
        );
      }
      tournamentRow = Map<String, dynamic>.from(row);

      final tournamentTeams = await client
          .from('tournament_teams')
          .select()
          .eq('tournament_sync_id', tournamentSyncId)
          .order('team_sync_id');
      tournamentTeamRows = tournamentTeams
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      final pointsRules = await client
          .from('tournament_points_rules')
          .select()
          .eq('tournament_sync_id', tournamentSyncId)
          .maybeSingle();
      if (pointsRules != null) {
        pointsRulesRow = Map<String, dynamic>.from(pointsRules);
      }
    }

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
      matchTeams: matchTeamRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      matchPlayers: matchPlayerRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      tournament: tournamentRow,
      tournamentTeams: tournamentTeamRows,
      tournamentPointsRules: pointsRulesRow,
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
