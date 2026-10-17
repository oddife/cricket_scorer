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
        .where((value) => value.isNotEmpty)
        .toSet();
    final playerSyncIds = matchPlayerRows
        .map((row) => row['player_sync_id']?.toString())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();
    final hasPlayerAssignments = matchPlayerRows.any((row) {
      final syncId = row['player_sync_id']?.toString();
      final globalId = row['player_global_id']?.toString();
      return (syncId != null && syncId.isNotEmpty) ||
          (globalId != null && globalId.isNotEmpty);
    });
    if (!hasPlayerAssignments) {
      throw StateError(
        'Synchronized match $matchSyncId has no player assignments.',
      );
    }

    // Newer clients can populate canonical relationship columns even when a
    // legacy *_sync_id is null. Collect those global IDs too, then resolve the
    // relation back to the catalog's stable sync_id during recovery.
    final teamGlobalIds = <String>{};
    void addTeamGlobal(dynamic value) {
      final id = value?.toString();
      if (id != null && id.isNotEmpty) teamGlobalIds.add(id);
    }
    for (final row in [...matchTeamRows, ...matchPlayerRows]) {
      addTeamGlobal(row['team_global_id']);
    }
    addTeamGlobal(matchRow['toss_winner_team_global_id']);
    for (final row in inningsRows) {
      addTeamGlobal(row['batting_team_global_id']);
      addTeamGlobal(row['bowling_team_global_id']);
    }

    final legacyTeamRows = teamSyncIds.isEmpty
        ? <Map<String, dynamic>>[]
        : (await client
                .from('teams')
                .select()
                .inFilter('sync_id', teamSyncIds.toList())
                .order('sync_id'))
            .map<Map<String, dynamic>>(
                (row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final canonicalTeamRows = teamGlobalIds.isEmpty
        ? <Map<String, dynamic>>[]
        : (await client
                .from('teams')
                .select()
                .inFilter('global_id', teamGlobalIds.toList())
                .order('sync_id'))
            .map<Map<String, dynamic>>(
                (row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final teamRowsBySyncId = <String, Map<String, dynamic>>{};
    for (final row in [...legacyTeamRows, ...canonicalTeamRows]) {
      final syncId = row['sync_id']?.toString();
      if (syncId != null && syncId.isNotEmpty) {
        teamRowsBySyncId[syncId] = row;
      }
    }
    final teamRows = teamRowsBySyncId.values.toList(growable: false);
    final resolvedTeamSyncIds = teamRows
        .map((row) => row['sync_id']?.toString())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();
    final teamSyncByGlobalId = <String, String>{
      for (final row in teamRows)
        if (row['global_id'] != null &&
            row['global_id'].toString().isNotEmpty)
          row['global_id'].toString(): row['sync_id'].toString(),
    };

    if (teamRows.isEmpty || (teamSyncIds.isEmpty && teamGlobalIds.isEmpty)) {
      throw StateError('Synchronized match $matchSyncId has no resolvable team assignments.');
    }

    final playerRows = playerSyncIds.isEmpty
        ? <Map<String, dynamic>>[]
        : (await client
                .from('players')
                .select()
                .inFilter('sync_id', playerSyncIds.toList())
                .order('sync_id'))
            .map<Map<String, dynamic>>(
                (row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final membershipLegacyRows = resolvedTeamSyncIds.isEmpty
        ? <Map<String, dynamic>>[]
        : (await client
                .from('team_players')
                .select()
                .inFilter('team_sync_id', resolvedTeamSyncIds.toList())
                .order('sync_id'))
            .map<Map<String, dynamic>>(
                (row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final membershipGlobalRows = teamGlobalIds.isEmpty
        ? <Map<String, dynamic>>[]
        : (await client
                .from('team_players')
                .select()
                .inFilter('team_global_id', teamGlobalIds.toList())
                .order('sync_id'))
            .map<Map<String, dynamic>>(
                (row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
    final membershipBySyncId = <String, Map<String, dynamic>>{};
    for (final row in [...membershipLegacyRows, ...membershipGlobalRows]) {
      final syncId = row['sync_id']?.toString();
      if (syncId != null && syncId.isNotEmpty) membershipBySyncId[syncId] = row;
    }
    final membershipRows = membershipBySyncId.values.toList(growable: false);

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
        'active_two_bowler_one_id',
        'active_two_bowler_two_id',
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

    // Fetch players directly referenced by canonical global IDs in match
    // relationships, team memberships, innings setup and ball events. This
    // avoids assuming a device-local integer ID is stable across installations.
    final referencedPlayerGlobalIds = <String>{};
    for (final row in membershipRows) {
      final value = row['player_global_id']?.toString();
      if (value != null && value.isNotEmpty) {
        referencedPlayerGlobalIds.add(value);
      }
    }
    for (final row in matchPlayerRows) {
      final value = row['player_global_id']?.toString();
      if (value != null && value.isNotEmpty) {
        referencedPlayerGlobalIds.add(value);
      }
    }
    for (final row in inningsRows) {
      for (final field in const [
        'opening_striker_global_id',
        'opening_non_striker_global_id',
        'opening_bowler_global_id',
        'active_two_bowler_one_global_id',
        'active_two_bowler_two_global_id',
      ]) {
        final value = row[field]?.toString();
        if (value != null && value.isNotEmpty) {
          referencedPlayerGlobalIds.add(value);
        }
      }
    }
    for (final row in ballRows) {
      for (final field in const [
        'bowler_global_id',
        'striker_global_id',
        'non_striker_global_id',
        'dismissed_player_global_id',
        'fielder_global_id',
        'replacement_batter_global_id',
      ]) {
        final value = row[field]?.toString();
        if (value != null && value.isNotEmpty) {
          referencedPlayerGlobalIds.add(value);
        }
      }
    }
    final canonicalPlayerRows = <Map<String, dynamic>>[];
    if (referencedPlayerGlobalIds.isNotEmpty) {
      final rows = await client
          .from('players')
          .select()
          .inFilter('global_id', referencedPlayerGlobalIds.toList())
          .order('sync_id');
      canonicalPlayerRows.addAll(
        rows.map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row),
        ),
      );
    }

    final membershipPlayerSyncIds = membershipRows
        .map((row) => row['player_sync_id']?.toString())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();
    final extraMembershipPlayerRows = membershipPlayerSyncIds.isEmpty
        ? <Map<String, dynamic>>[]
        : (await client
                .from('players')
                .select()
                .inFilter('sync_id', membershipPlayerSyncIds.toList())
                .order('sync_id'))
            .map<Map<String, dynamic>>(
                (row) => Map<String, dynamic>.from(row))
            .toList(growable: false);

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
    for (final row in [...canonicalPlayerRows, ...extraMembershipPlayerRows]) {
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
    for (final row in [...canonicalPlayerRows, ...extraMembershipPlayerRows]) {
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
            row['active_two_bowler_one_id']?.toString(),
            row['active_two_bowler_two_id']?.toString(),
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

    final playerSyncByGlobalId = <String, String>{
      for (final row in allPlayerRows)
        if (row['global_id'] != null &&
            row['global_id'].toString().isNotEmpty)
          row['global_id'].toString(): row['sync_id'].toString(),
    };
    final normalizedMatchTeams = matchTeamRows
        .map<Map<String, dynamic>>((row) {
          final normalized = Map<String, dynamic>.from(row);
          final legacyId = normalized['team_sync_id']?.toString();
          final globalId = normalized['team_global_id']?.toString();
          if ((legacyId == null || legacyId.isEmpty) &&
              globalId != null && globalId.isNotEmpty) {
            normalized['team_sync_id'] = teamSyncByGlobalId[globalId];
          }
          return normalized;
        })
        .toList(growable: false);
    final normalizedMatchPlayers = matchPlayerRows
        .map<Map<String, dynamic>>((row) {
          final normalized = Map<String, dynamic>.from(row);
          final teamSync = normalized['team_sync_id']?.toString();
          final teamGlobal = normalized['team_global_id']?.toString();
          final playerSync = normalized['player_sync_id']?.toString();
          final playerGlobal = normalized['player_global_id']?.toString();
          if ((teamSync == null || teamSync.isEmpty) &&
              teamGlobal != null && teamGlobal.isNotEmpty) {
            normalized['team_sync_id'] = teamSyncByGlobalId[teamGlobal];
          }
          if ((playerSync == null || playerSync.isEmpty) &&
              playerGlobal != null && playerGlobal.isNotEmpty) {
            normalized['player_sync_id'] = playerSyncByGlobalId[playerGlobal];
          }
          return normalized;
        })
        .toList(growable: false);

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
          .where((row) {
            final teamSyncId = row['team_sync_id']?.toString();
            final teamGlobalId = row['team_global_id']?.toString();
            return (teamSyncId != null &&
                    resolvedTeamSyncIds.contains(teamSyncId)) ||
                (teamGlobalId != null &&
                    teamGlobalIds.contains(teamGlobalId));
          })
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
      matchTeams: normalizedMatchTeams,
      matchPlayers: normalizedMatchPlayers,
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
