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

  Future<List<Map<String, dynamic>>> listMatches() async {
    final client = _requireAuthenticatedClient();
    final rows = await client
        .from('matches')
        .select()
        .order('updated_at', ascending: false);
    return rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

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

    final teamSyncIds = matchTeamRows
        .map((row) => row['team_sync_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final playerSyncIds = matchPlayerRows
        .map((row) => row['player_sync_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList(growable: false);

    if (teamSyncIds.isEmpty) {
      throw StateError('Synchronized match $matchSyncId has no team assignments.');
    }
    if (playerSyncIds.isEmpty) {
      throw StateError('Synchronized match $matchSyncId has no player assignments.');
    }

    final teamRows = await client
        .from('teams')
        .select()
        .inFilter('sync_id', teamSyncIds)
        .order('sync_id');
    final playerRows = await client
        .from('players')
        .select()
        .inFilter('sync_id', playerSyncIds)
        .order('sync_id');
    final membershipRows = await client
        .from('team_players')
        .select()
        .inFilter('team_sync_id', teamSyncIds)
        .order('sync_id');

    // Match events can reference players by the originating device's local
    // ID. The current match_players rows may point at a newer player catalog
    // entry, so fetch the historical player rows referenced by the innings
    // and ball events as well. This is essential when a roster was recreated
    // after an older match was scored.
    final referencedPlayerLocalIds = <String>{};
    for (final row in inningsRows) {
      for (final field in const [
        'opening_striker_id',
        'opening_non_striker_id',
        'opening_bowler_id',
      ]) {
        final value = row[field]?.toString();
        if (value != null && value.isNotEmpty) {
          referencedPlayerLocalIds.add(value);
        }
      }
    }
    for (final row in ballRows) {
      for (final field in const [
        'bowler_id',
        'striker_id',
        'non_striker_id',
        'dismissed_player_id',
        'fielder_id',
        'replacement_batter_id',
      ]) {
        final value = row[field]?.toString();
        if (value != null && value.isNotEmpty) {
          referencedPlayerLocalIds.add(value);
        }
      }
    }

    final playerSourceCandidates = <String>{};
    final matchSource = matchRow['source_installation_id']?.toString();
    if (matchSource != null && matchSource.isNotEmpty) {
      playerSourceCandidates.add(matchSource);
    }
    for (final row in playerRows) {
      final source = row['source_installation_id']?.toString();
      if (source != null && source.isNotEmpty) {
        playerSourceCandidates.add(source);
      }
    }

    final historicalPlayerRows = <Map<String, dynamic>>[];
    if (referencedPlayerLocalIds.isNotEmpty && playerSourceCandidates.isNotEmpty) {
      final rows = await client
          .from('players')
          .select()
          .inFilter('source_installation_id', playerSourceCandidates.toList())
          .inFilter('local_id', referencedPlayerLocalIds.toList())
          .order('source_installation_id')
          .order('local_id');
      historicalPlayerRows.addAll(
        rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)),
      );
    }

    // Keep both the current match-assigned players and historical event
    // players. They have different sync IDs and represent different catalog
    // records, so de-duplicate only by sync_id.
    final allPlayerRowsBySyncId = <String, Map<String, dynamic>>{};
    for (final row in playerRows) {
      final syncId = row['sync_id']?.toString();
      if (syncId != null && syncId.isNotEmpty) {
        allPlayerRowsBySyncId[syncId] = Map<String, dynamic>.from(row);
      }
    }
    for (final row in historicalPlayerRows) {
      final syncId = row['sync_id']?.toString();
      if (syncId != null && syncId.isNotEmpty) {
        allPlayerRowsBySyncId[syncId] = Map<String, dynamic>.from(row);
      }
    }
    final allPlayerRows = allPlayerRowsBySyncId.values.toList(growable: false);

    // Older records can contain local IDs from the originating device while
    // the parent match row carries the match installation ID. Build the
    // source identity from the actual catalog rows fetched for this match.
    final teamSourceByLocalId = <String, Set<String>>{};
    for (final row in teamRows) {
      final localId = row['local_id']?.toString();
      final source = row['source_installation_id']?.toString();
      if (localId == null || source == null || source.isEmpty) continue;
      (teamSourceByLocalId[localId] ??= <String>{}).add(source);
    }

    final playerSourceByLocalId = <String, Set<String>>{};
    for (final row in allPlayerRows) {
      final localId = row['local_id']?.toString();
      final source = row['source_installation_id']?.toString();
      if (localId == null || source == null || source.isEmpty) continue;
      (playerSourceByLocalId[localId] ??= <String>{}).add(source);
    }

    final normalizedInnings = inningsRows
        .map<Map<String, dynamic>>((row) {
          final normalized = Map<String, dynamic>.from(row);
          final battingLocalId = row['batting_team_id']?.toString();
          final bowlingLocalId = row['bowling_team_id']?.toString();
          final battingSources = battingLocalId == null
              ? const <String>{}
              : (teamSourceByLocalId[battingLocalId] ?? const <String>{});
          final bowlingSources = bowlingLocalId == null
              ? const <String>{}
              : (teamSourceByLocalId[bowlingLocalId] ?? const <String>{});

          if (battingSources.length == 1 &&
              bowlingSources.length == 1 &&
              battingSources.single == bowlingSources.single) {
            normalized['source_installation_id'] = battingSources.single;
          }

          final openingPlayerLocalIds = <String?>[
            row['opening_striker_id']?.toString(),
            row['opening_non_striker_id']?.toString(),
            row['opening_bowler_id']?.toString(),
          ].whereType<String>().where((id) => id.isNotEmpty).toSet();
          final openingPlayerSources = <String>{};
          for (final localId in openingPlayerLocalIds) {
            final sources = playerSourceByLocalId[localId];
            if (sources != null) {
              openingPlayerSources.addAll(sources);
            }
          }
          if (openingPlayerSources.length == 1) {
            normalized['source_installation_id'] = openingPlayerSources.single;
          }

          return normalized;
        })
        .toList(growable: false);

    // Ball player IDs are also originating-device local IDs. Normalize the
    // row source to the actual player catalog source before recovery resolves
    // bowler/striker/non-striker and wicket-related player references.
    final normalizedBallEvents = ballRows
        .map<Map<String, dynamic>>((row) {
          final normalized = Map<String, dynamic>.from(row);
          final candidateLocalIds = <String?>[
            row['bowler_id']?.toString(),
            row['striker_id']?.toString(),
            row['non_striker_id']?.toString(),
            row['dismissed_player_id']?.toString(),
            row['fielder_id']?.toString(),
            row['replacement_batter_id']?.toString(),
          ].whereType<String>().where((id) => id.isNotEmpty).toSet();

          final sources = <String>{};
          for (final localId in candidateLocalIds) {
            final playerSources = playerSourceByLocalId[localId];
            if (playerSources != null) {
              sources.addAll(playerSources);
            }
          }

          if (sources.length == 1) {
            normalized['source_installation_id'] = sources.single;
          }
          return normalized;
        })
        .toList(growable: false);

    // Match toss_winner_team_id is also an originating-device team local ID.
    // The match row itself can still carry the match installation ID, so
    // normalize its source to the actual team source before the importer
    // resolves the toss winner.
    final normalizedMatch = Map<String, dynamic>.from(matchRow);
    final tossWinnerLocalId = matchRow['toss_winner_team_id']?.toString();
    if (tossWinnerLocalId != null && tossWinnerLocalId.isNotEmpty) {
      final tossSources = teamSourceByLocalId[tossWinnerLocalId] ?? const <String>{};
      if (tossSources.length == 1) {
        normalizedMatch['source_installation_id'] = tossSources.single;
      }
    }

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
          .inFilter('team_sync_id', teamSyncIds)
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
      match: normalizedMatch,
      innings: normalizedInnings,
      ballEvents: normalizedBallEvents,
      teams: teamRows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
      players: allPlayerRows,
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
