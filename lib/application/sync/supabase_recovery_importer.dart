import 'package:drift/drift.dart';

import '../../data/database/app_database.dart' as db;
import 'supabase_recovery_transport.dart';

/// Atomically imports a server snapshot into the local authoritative SQLite DB.
///
/// Recovery uses the server's stable sync IDs as identity and translates the
/// originating-device local IDs in innings/ball rows into this device's local
/// IDs. Nothing imported by recovery is added to the upload queue.
class SupabaseRecoveryImporter {
  const SupabaseRecoveryImporter(this._db);

  final db.AppDatabase _db;

  Future<int> importMatch(RemoteMatchSnapshot snapshot) {
    return _db.transaction(() async {
      _validateSnapshot(snapshot);
      final teamSyncToLocal = await _importTeams(snapshot.teams);
      final playerSyncToLocal = await _importPlayers(snapshot.players);
      await _importTeamPlayers(snapshot.teamPlayers, teamSyncToLocal, playerSyncToLocal);

      final teamSourceToSync = _sourceMap(snapshot.teams);
      final playerSourceToSync = _sourceMap(snapshot.players);
      final tournamentId = await _importTournament(
        snapshot.tournament,
        snapshot.tournamentTeams,
        snapshot.tournamentPointsRules,
        teamSyncToLocal,
      );
      final matchId = await _importMatch(
        snapshot.match,
        teamSourceToSync,
        teamSyncToLocal,
        tournamentId,
      );
      await _importMatchTeams(snapshot.matchTeams, matchId, teamSyncToLocal);
      await _importMatchPlayers(snapshot.matchPlayers, matchId, teamSyncToLocal, playerSyncToLocal);

      final inningsIds = <String, int>{};
      for (final row in snapshot.innings) {
        inningsIds[_required(row, 'sync_id')] = await _importInnings(
          row, matchId, teamSourceToSync, playerSourceToSync, teamSyncToLocal, playerSyncToLocal,
        );
      }
      for (final row in snapshot.ballEvents) {
        await _importBallEvent(row, inningsIds, playerSourceToSync, playerSyncToLocal);
      }
      return matchId;
    });
  }

  Future<Map<String, int>> _importTeams(List<Map<String, dynamic>> rows) async {
    final result = <String, int>{};
    for (final row in rows) {
      final syncId = _required(row, 'sync_id');
      final existing = await _identityLocalId('team', syncId);
      if (existing != null) {
        final local = await (_db.select(_db.teams)..where((t) => t.id.equals(existing))).getSingleOrNull();
        if (local == null) throw StateError('Recovery identity $syncId points to missing team $existing.');
        _eq('team name', local.name, _required(row, 'name'));
        _eq('team short_name', local.shortName, _required(row, 'short_name'));
        _eq('team logo_path', local.logoPath, row['logo_path']);
        _eq('team is_active', local.isActive, _bool(row['is_active']));
        result[syncId] = existing;
        continue;
      }
      final now = _date(row['updated_at']) ?? DateTime.now();
      final id = await _db.into(_db.teams).insert(db.TeamsCompanion.insert(
        name: _required(row, 'name'), shortName: _required(row, 'short_name'),
        logoPath: Value(row['logo_path'] as String?), isActive: Value(_bool(row['is_active'])),
        createdAt: now, updatedAt: now,
      ));
      await _saveIdentity('team', id, syncId);
      result[syncId] = id;
    }
    return result;
  }

  Future<Map<String, int>> _importPlayers(List<Map<String, dynamic>> rows) async {
    final result = <String, int>{};
    for (final row in rows) {
      final syncId = _required(row, 'sync_id');
      final existing = await _identityLocalId('player', syncId);
      if (existing != null) {
        final local = await (_db.select(_db.players)..where((p) => p.id.equals(existing))).getSingleOrNull();
        if (local == null) throw StateError('Recovery identity $syncId points to missing player $existing.');
        _eq('player name', local.name, _required(row, 'name'));
        _eq('player display_name', local.displayName, _required(row, 'display_name'));
        _eq('player photo_path', local.photoPath, row['photo_path']);
        _eq('player jersey_number', local.jerseyNumber, row['jersey_number']);
        _eq('player batting_style', local.battingStyle, row['batting_style']);
        _eq('player bowling_style', local.bowlingStyle, row['bowling_style']);
        _eq('player is_active', local.isActive, _bool(row['is_active']));
        result[syncId] = existing;
        continue;
      }
      final now = _date(row['updated_at']) ?? DateTime.now();
      final id = await _db.into(_db.players).insert(db.PlayersCompanion.insert(
        name: _required(row, 'name'), displayName: _required(row, 'display_name'),
        photoPath: Value(row['photo_path'] as String?), jerseyNumber: Value(row['jersey_number'] as int?),
        battingStyle: Value(row['batting_style'] as int), bowlingStyle: Value(row['bowling_style'] as int),
        isActive: Value(_bool(row['is_active'])), createdAt: now, updatedAt: now,
      ));
      await _saveIdentity('player', id, syncId);
      result[syncId] = id;
    }
    return result;
  }

  Future<void> _importTeamPlayers(
    List<Map<String, dynamic>> rows,
    Map<String, int> teams,
    Map<String, int> players,
  ) async {
    for (final row in rows) {
      final syncId = _required(row, 'sync_id');
      final teamId = _resolve(teams, row['team_sync_id'], 'team');
      final playerId = _resolve(players, row['player_sync_id'], 'player');
      final existing = await _identityLocalId('team_player', syncId);
      if (existing != null) {
        final local = await (_db.select(_db.teamPlayers)..where((m) => m.id.equals(existing))).getSingleOrNull();
        if (local == null) throw StateError('Recovery identity $syncId points to missing team-player $existing.');
        _eq('team-player team', local.teamId, teamId);
        _eq('team-player player', local.playerId, playerId);
        _eq('team-player jersey_number', local.jerseyNumber, row['jersey_number']);
        _eq('team-player is_active', local.isActive, _bool(row['is_active']));
        continue;
      }
      final duplicate = await (_db.select(_db.teamPlayers)
            ..where((m) => m.teamId.equals(teamId) & m.playerId.equals(playerId)))
          .getSingleOrNull();
      if (duplicate != null) throw StateError('Recovery divergence: team-player membership has a different sync identity.');
      final id = await _db.into(_db.teamPlayers).insert(db.TeamPlayersCompanion.insert(
        teamId: teamId, playerId: playerId,
        jerseyNumber: Value(row['jersey_number'] as int?),
        isActive: Value(_bool(row['is_active'])),
        createdAt: _date(row['created_at']) ?? DateTime.now(),
      ));
      await _saveIdentity('team_player', id, syncId);
    }
  }

  Future<int?> _importTournament(
    Map<String, dynamic>? row,
    List<Map<String, dynamic>> teamRows,
    Map<String, dynamic>? pointsRules,
    Map<String, int> teams,
  ) async {
    if (row == null) {
      if (teamRows.isNotEmpty || pointsRules != null) {
        throw StateError('Recovery tournament data exists without tournament metadata.');
      }
      return null;
    }

    final syncId = _required(row, 'sync_id');
    final existing = await _identityLocalId('tournament', syncId);
    final startDate = _date(row['start_date']);
    final endDate = _date(row['end_date']);
    late final int tournamentId;

    if (existing != null) {
      final local = await (_db.select(_db.tournaments)..where((t) => t.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing tournament $existing.');
      _eq('tournament name', local.name, _required(row, 'name'));
      _eq('tournament type', local.tournamentType, row['tournament_type']);
      _eq('tournament logo_path', local.logoPath, row['logo_path']);
      _eq('tournament start_date', local.startDate, startDate);
      _eq('tournament end_date', local.endDate, endDate);
      _eq('tournament is_active', local.isActive, _bool(row['is_active']));
      tournamentId = existing;
    } else {
      final now = _date(row['updated_at']) ?? DateTime.now();
      tournamentId = await _db.into(_db.tournaments).insert(db.TournamentsCompanion.insert(
        name: _required(row, 'name'), tournamentType: row['tournament_type'] as int,
        logoPath: Value(row['logo_path'] as String?), startDate: Value(startDate), endDate: Value(endDate),
        isActive: Value(_bool(row['is_active'])), createdAt: now, updatedAt: now,
      ));
      await _saveIdentity('tournament', tournamentId, syncId);
    }

    final remoteTeamIds = <int>{};
    for (final teamRow in teamRows) {
      final teamId = _resolve(teams, teamRow['team_sync_id'], 'team');
      remoteTeamIds.add(teamId);
      final existingMembership = await (_db.select(_db.tournamentTeams)
            ..where((t) => t.tournamentId.equals(tournamentId) & t.teamId.equals(teamId)))
          .getSingleOrNull();
      if (existingMembership == null) {
        await _db.into(_db.tournamentTeams).insert(db.TournamentTeamsCompanion.insert(
          tournamentId: tournamentId, teamId: teamId,
          createdAt: _date(teamRow['created_at']) ?? DateTime.now(),
        ));
      }
    }

    final existingMemberships = await (_db.select(_db.tournamentTeams)
          ..where((t) => t.tournamentId.equals(tournamentId)))
        .get();
    for (final membership in existingMemberships) {
      if (!remoteTeamIds.contains(membership.teamId)) {
        await (_db.delete(_db.tournamentTeams)..where((t) => t.id.equals(membership.id))).go();
      }
    }

    if (pointsRules != null) {
      final rulesTournamentId = _required(pointsRules, 'tournament_sync_id');
      _eq('tournament points sync_id', rulesTournamentId, syncId);
      await _db.customStatement(
        '''
        INSERT INTO tournament_points_rules
          (tournament_id, win_points, tie_points, no_result_points, loss_points)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(tournament_id) DO UPDATE SET
          win_points = excluded.win_points,
          tie_points = excluded.tie_points,
          no_result_points = excluded.no_result_points,
          loss_points = excluded.loss_points
        ''',
        [tournamentId, pointsRules['win_points'] as int, pointsRules['tie_points'] as int,
          pointsRules['no_result_points'] as int, pointsRules['loss_points'] as int],
      );
    } else {
      await (_db.delete(_db.tournamentPointsRules)
            ..where((t) => t.tournamentId.equals(tournamentId)))
          .go();
    }

    return tournamentId;
  }

  Future<int> _importMatch(
    Map<String, dynamic> row,
    Map<String, String> teamSourceToSync,
    Map<String, int> teams,
    int? tournamentId,
  ) async {
    final syncId = _required(row, 'sync_id');
    final tossTeamId = row['toss_winner_team_id'] == null ? null : _resolveSourceLocal(teams, teamSourceToSync, row['toss_winner_team_id'], row, 'team');
    final existing = await _identityLocalId('match', syncId);
    if (existing != null) {
      final local = await (_db.select(_db.matches)..where((m) => m.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing match $existing.');
      _eq('match tournament', local.tournamentId, tournamentId);
      _eq('match name', local.name, _required(row, 'name'));
      _eq('match date', local.date.toUtc(), DateTime.parse(_required(row, 'date')).toUtc());
      _eq('match venue', local.venue, row['venue']);
      _eq('match innings_count', local.inningsCount, row['innings_count']);
      _eq('match overs_per_innings', local.oversPerInnings, row['overs_per_innings']);
      _eq('match balls_per_over', local.ballsPerOver, row['balls_per_over']);
      _eq('match players_per_team', local.playersPerTeam, row['players_per_team']);
      _eq('match two_bowler_mode', local.twoBowlerMode, _bool(row['two_bowler_mode']));
      _eq('match toss_winner_team_id', local.tossWinnerTeamId, tossTeamId);
      _eq('match toss_decision', local.tossDecision, row['toss_decision']);
      _eq('match status', local.status, row['status']);
      return existing;
    }
    final id = await _db.into(_db.matches).insert(db.MatchesCompanion.insert(
      tournamentId: Value(tournamentId), name: _required(row, 'name'), date: DateTime.parse(_required(row, 'date')).toLocal(),
      venue: Value(row['venue'] as String?), inningsCount: row['innings_count'] as int,
      oversPerInnings: row['overs_per_innings'] as int, ballsPerOver: row['balls_per_over'] as int,
      playersPerTeam: row['players_per_team'] as int, twoBowlerMode: Value(_bool(row['two_bowler_mode'])),
      tossWinnerTeamId: Value(tossTeamId), tossDecision: Value(row['toss_decision'] as int?), status: Value(row['status'] as int),
      createdAt: _date(row['created_at']) ?? DateTime.now(), updatedAt: _date(row['updated_at']) ?? DateTime.now(),
    ));
    await _saveIdentity('match', id, syncId);
    return id;
  }

  Future<void> _importMatchTeams(List<Map<String, dynamic>> rows, int matchId, Map<String, int> teams) async {
    for (final row in rows) {
      final slot = row['slot'] as int;
      final teamId = _resolve(teams, row['team_sync_id'], 'team');
      final existing = await (_db.select(_db.matchTeams)..where((t) => t.matchId.equals(matchId) & t.slot.equals(slot))).getSingleOrNull();
      if (existing != null) { _eq('match team slot $slot', existing.teamId, teamId); }
      else {
        final duplicate = await (_db.select(_db.matchTeams)..where((t) => t.matchId.equals(matchId) & t.teamId.equals(teamId))).getSingleOrNull();
        if (duplicate != null) throw StateError('Recovery divergence: duplicate match team assignment.');
        await _db.into(_db.matchTeams).insert(db.MatchTeamsCompanion.insert(matchId: matchId, teamId: teamId, slot: slot));
      }
    }
  }

  Future<void> _importMatchPlayers(List<Map<String, dynamic>> rows, int matchId, Map<String, int> teams, Map<String, int> players) async {
    for (final row in rows) {
      final playerId = _resolve(players, row['player_sync_id'], 'player');
      final teamId = _resolve(teams, row['team_sync_id'], 'team');
      final existing = await (_db.select(_db.matchPlayers)..where((p) => p.matchId.equals(matchId) & p.playerId.equals(playerId))).getSingleOrNull();
      if (existing != null) {
        _eq('match player team', existing.teamId, teamId);
        _eq('match player is_playing', existing.isPlaying, _bool(row['is_playing']));
        _eq('match player batting_order', existing.battingOrder, row['batting_order']);
      } else {
        await _db.into(_db.matchPlayers).insert(db.MatchPlayersCompanion.insert(
          matchId: matchId, teamId: teamId, playerId: playerId,
          isPlaying: Value(_bool(row['is_playing'])), battingOrder: Value(row['batting_order'] as int?),
        ));
      }
    }
  }

  // Remaining recovery helpers intentionally stay unchanged.
  Future<int> _importInnings(Map<String, dynamic> row, int matchId, Map<String, String> teamSourceToSync, Map<String, String> playerSourceToSync, Map<String, int> teams, Map<String, int> players) async {
    final syncId = _required(row, 'sync_id');
    final existing = await _identityLocalId('innings', syncId);
    final battingTeamId = _resolveSourceLocal(teams, teamSourceToSync, row['batting_team_id'], row, 'team');
    final bowlingTeamId = _resolveSourceLocal(teams, teamSourceToSync, row['bowling_team_id'], row, 'team');
    final openingStrikerId = _resolveSourceLocal(players, playerSourceToSync, row['opening_striker_id'], row, 'player');
    final openingNonStrikerId = _resolveSourceLocal(players, playerSourceToSync, row['opening_non_striker_id'], row, 'player');
    final openingBowlerId = _resolveSourceLocal(players, playerSourceToSync, row['opening_bowler_id'], row, 'player');
    if (existing != null) {
      final local = await (_db.select(_db.innings)..where((i) => i.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing innings $existing.');
      _eq('innings match', local.matchId, matchId); _eq('innings number', local.inningsNumber, row['innings_number']);
      _eq('innings batting team', local.battingTeamId, battingTeamId); _eq('innings bowling team', local.bowlingTeamId, bowlingTeamId);
      _eq('innings opening striker', local.openingStrikerId, openingStrikerId); _eq('innings opening non-striker', local.openingNonStrikerId, openingNonStrikerId); _eq('innings opening bowler', local.openingBowlerId, openingBowlerId);
      _eq('innings overs', local.oversPerInnings, row['overs_per_innings']); _eq('innings balls', local.ballsPerOver, row['balls_per_over']);
      _eq('innings two-bowler', local.twoBowlerMode, _bool(row['two_bowler_mode'])); _eq('innings status', local.status.name, _required(row, 'status'));
      return existing;
    }
    final id = await _db.into(_db.innings).insert(db.InningsCompanion.insert(
      matchId: matchId, inningsNumber: row['innings_number'] as int, battingTeamId: battingTeamId, bowlingTeamId: bowlingTeamId,
      openingStrikerId: openingStrikerId, openingNonStrikerId: openingNonStrikerId, openingBowlerId: openingBowlerId,
      oversPerInnings: row['overs_per_innings'] as int, ballsPerOver: row['balls_per_over'] as int,
      twoBowlerMode: _bool(row['two_bowler_mode']), status: row['status'] as String,
      startedAt: Value(_date(row['started_at'])), completedAt: Value(_date(row['completed_at'])),
    ));
    await _saveIdentity('innings', id, syncId); return id;
  }

  Future<void> _importBallEvent(Map<String, dynamic> row, Map<String, int> innings, Map<String, String> playerSourceToSync, Map<String, int> players) async {
    final syncId = _required(row, 'sync_id'); final inningsSyncId = _required(row, 'innings_sync_id');
    final inningsId = innings[inningsSyncId]; if (inningsId == null) throw StateError('Recovery BallEvent $syncId references missing innings $inningsSyncId.');
    final strikerId = _resolveSourceLocal(players, playerSourceToSync, row['striker_id'], row, 'player');
    final nonStrikerId = _resolveSourceLocal(players, playerSourceToSync, row['non_striker_id'], row, 'player');
    final bowlerId = _resolveSourceLocal(players, playerSourceToSync, row['bowler_id'], row, 'player');
    final existing = await _identityLocalId('ball_event', syncId);
    if (existing != null) {
      final local = await (_db.select(_db.ballEvents)..where((b) => b.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing BallEvent $existing.');
      _eq('BallEvent innings', local.inningsId, inningsId); _eq('BallEvent sequence', local.sequenceNumber, row['sequence_number']);
      _eq('BallEvent striker', local.strikerId, strikerId); _eq('BallEvent non-striker', local.nonStrikerId, nonStrikerId); _eq('BallEvent bowler', local.bowlerId, bowlerId);
      _eq('BallEvent runs', local.runsOffBat, row['runs_off_bat']); _eq('BallEvent extras', local.extras, row['extras']); _eq('BallEvent legal', local.isLegal, _bool(row['is_legal']));
      _eq('BallEvent extras type', local.extrasType, row['extras_type']); _eq('BallEvent wicket', local.wicketType, row['wicket_type']);
      return;
    }
    final id = await _db.into(_db.ballEvents).insert(db.BallEventsCompanion.insert(
      inningsId: inningsId, sequenceNumber: row['sequence_number'] as int, strikerId: strikerId, nonStrikerId: nonStrikerId, bowlerId: bowlerId,
      runsOffBat: row['runs_off_bat'] as int, extras: row['extras'] as int, isLegal: _bool(row['is_legal']),
      extrasType: Value(row['extras_type'] as String?), wicketType: Value(row['wicket_type'] as String?),
      createdAt: _date(row['created_at']) ?? DateTime.now(),
    ));
    await _saveIdentity('ball_event', id, syncId);
    if (row['wicket_context'] != null) {
      final context = Map<String, dynamic>.from(row['wicket_context'] as Map);
      await _db.customStatement('''INSERT OR REPLACE INTO wicket_event_contexts (ball_event_id, completed_runs, crossed_before_wicket, replacement_batter_id) VALUES (?, ?, ?, ?)''', [id, context['completed_runs'] as int, _bool(context['crossed_before_wicket']) ? 1 : 0, context['replacement_batter_id'] == null ? null : _resolveSourceLocal(players, playerSourceToSync, context['replacement_batter_id'], row, 'player')]);
    }
  }

  Map<String, String> _sourceMap(List<Map<String, dynamic>> rows) => {
    for (final row in rows) '${row['source_installation_id']}:${row['local_id']}': _required(row, 'sync_id'),
  };

  Future<int?> _identityLocalId(String type, String syncId) async {
    final rows = await _db.customSelect('SELECT local_id FROM sync_entity_identities WHERE entity_type = ? AND sync_id = ? LIMIT 1', variables: [Variable.withString(type), Variable.withString(syncId)]).get();
    return rows.isEmpty ? null : rows.single.data['local_id'] as int;
  }

  Future<void> _saveIdentity(String type, int localId, String syncId) async {
    await _db.customStatement('INSERT INTO sync_entity_identities (entity_type, local_id, sync_id, created_at) VALUES (?, ?, ?, ?) ON CONFLICT(entity_type, local_id) DO UPDATE SET sync_id = excluded.sync_id', [type, localId, syncId, DateTime.now().toUtc().toIso8601String()]);
  }

  int _resolve(Map<String, int> values, dynamic syncId, String type) {
    final id = values[syncId?.toString()]; if (id == null) throw StateError('Recovery references missing $type sync identity ${syncId ?? '<null>'}.'); return id;
  }

  int _resolveSourceLocal(Map<String, int> values, Map<String, String> sourceToSync, dynamic sourceLocalId, Map<String, dynamic> row, String type) {
    final source = row['source_installation_id']?.toString(); if (source == null || source.isEmpty) throw StateError('Recovery $type row is missing source_installation_id.');
    final syncId = sourceToSync['$source:$sourceLocalId']; if (syncId == null) throw StateError('Recovery references missing $type source local ID $sourceLocalId from $source.'); return _resolve(values, syncId, type);
  }

  String _required(Map<String, dynamic> row, String key) { final value = row[key]?.toString(); if (value == null || value.isEmpty) throw StateError('Recovery row is missing required field $key.'); return value; }
  bool _bool(dynamic value) => value == true || value == 1 || value == 'true';
  DateTime? _date(dynamic value) => value == null ? null : DateTime.parse(value.toString()).toLocal();
  void _eq(String field, dynamic local, dynamic remote) { if (local != remote) throw StateError('Recovery divergence for $field: local=$local remote=$remote.'); }

  void _validateSnapshot(RemoteMatchSnapshot snapshot) {
    if (_required(snapshot.match, 'sync_id').isEmpty) throw StateError('Recovery match sync_id is required.');
    if (snapshot.innings.length != 2 && snapshot.innings.length != 4) throw StateError('Recovery requires exactly 2 or 4 innings.');
    if (snapshot.match['innings_count'] != snapshot.innings.length) throw StateError('Recovery innings count does not match the match.');
    if (snapshot.match['balls_per_over'] != 6) throw StateError('Recovery requires six balls per over.');
    if (snapshot.matchTeams.length != 2) throw StateError('Recovery requires exactly two match teams.');
    final inningsNumbers = snapshot.innings.map((row) => row['innings_number']).toSet();
    if (inningsNumbers.length != snapshot.innings.length) throw StateError('Recovery contains duplicate innings numbers.');
  }
}
