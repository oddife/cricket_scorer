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
      final matchId = await _importMatch(snapshot.match, teamSourceToSync, teamSyncToLocal);
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

  Future<void> _importTeamPlayers(List<Map<String, dynamic>> rows, Map<String, int> teams, Map<String, int> players) async {
    for (final row in rows) {
      final syncId = _required(row, 'sync_id');
      final teamId = _resolve(teams, row['team_sync_id'], 'team');
      final playerId = _resolve(players, row['player_sync_id'], 'player');
      final existing = await _identityLocalId('team_player', syncId);
      if (existing != null) {
        final local = await (_db.select(_db.teamPlayers)..where((t) => t.id.equals(existing))).getSingleOrNull();
        if (local == null) throw StateError('Recovery identity $syncId points to missing membership $existing.');
        _eq('membership team', local.teamId, teamId);
        _eq('membership player', local.playerId, playerId);
        _eq('membership jersey_number', local.jerseyNumber, row['jersey_number']);
        _eq('membership is_active', local.isActive, _bool(row['is_active']));
        continue;
      }
      final duplicate = await (_db.select(_db.teamPlayers)
            ..where((t) => t.teamId.equals(teamId) & t.playerId.equals(playerId))).getSingleOrNull();
      if (duplicate != null) throw StateError('Recovery divergence: membership $syncId conflicts with local membership ${duplicate.id}.');
      final id = await _db.into(_db.teamPlayers).insert(db.TeamPlayersCompanion.insert(
        teamId: teamId, playerId: playerId, jerseyNumber: Value(row['jersey_number'] as int?),
        isActive: Value(_bool(row['is_active'])), createdAt: _date(row['created_at']) ?? DateTime.now(),
      ));
      await _saveIdentity('team_player', id, syncId);
    }
  }

  Future<int> _importMatch(Map<String, dynamic> row, Map<String, String> teamSourceToSync, Map<String, int> teams) async {
    final syncId = _required(row, 'sync_id');
    final tossTeamId = row['toss_winner_team_id'] == null ? null : _resolveSourceLocal(teams, teamSourceToSync, row['toss_winner_team_id'], row, 'team');
    final existing = await _identityLocalId('match', syncId);
    if (existing != null) {
      final local = await (_db.select(_db.matches)..where((m) => m.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing match $existing.');
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
      tournamentId: const Value(null), name: _required(row, 'name'), date: DateTime.parse(_required(row, 'date')).toLocal(),
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
      final teamId = _resolve(teams, row['team_sync_id'], 'team');
      final playerId = _resolve(players, row['player_sync_id'], 'player');
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

  Future<int> _importInnings(Map<String, dynamic> row, int matchId, Map<String, String> teamSourceToSync, Map<String, String> playerSourceToSync, Map<String, int> teams, Map<String, int> players) async {
    final syncId = _required(row, 'sync_id');
    final battingTeam = _resolveSourceLocal(teams, teamSourceToSync, row['batting_team_id'], row, 'team');
    final bowlingTeam = _resolveSourceLocal(teams, teamSourceToSync, row['bowling_team_id'], row, 'team');
    final striker = _resolveSourceLocal(players, playerSourceToSync, row['opening_striker_id'], row, 'player');
    final nonStriker = _resolveSourceLocal(players, playerSourceToSync, row['opening_non_striker_id'], row, 'player');
    final bowler = _resolveSourceLocal(players, playerSourceToSync, row['opening_bowler_id'], row, 'player');
    final status = _inningsStatus(_required(row, 'status'));
    final existing = await _identityLocalId('innings', syncId);
    if (existing != null) {
      final local = await (_db.select(_db.innings)..where((i) => i.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing innings $existing.');
      _eq('innings match', local.matchId, matchId); _eq('innings number', local.inningsNumber, row['innings_number']);
      _eq('innings batting team', local.battingTeamId, battingTeam); _eq('innings bowling team', local.bowlingTeamId, bowlingTeam);
      _eq('innings striker', local.openingStrikerId, striker); _eq('innings non-striker', local.openingNonStrikerId, nonStriker); _eq('innings bowler', local.openingBowlerId, bowler);
      _eq('innings overs', local.oversPerInnings, row['overs_per_innings']); _eq('innings balls', local.ballsPerOver, row['balls_per_over']);
      _eq('innings two-bowler', local.twoBowlerMode, _bool(row['two_bowler_mode'])); _eq('innings status', local.status, status);
      return existing;
    }
    final duplicate = await (_db.select(_db.innings)..where((i) => i.matchId.equals(matchId) & i.inningsNumber.equals(row['innings_number'] as int))).getSingleOrNull();
    if (duplicate != null) throw StateError('Recovery divergence: innings number already exists locally.');
    final id = await _db.into(_db.innings).insert(db.InningsCompanion(
      matchId: Value(matchId), inningsNumber: Value(row['innings_number'] as int), battingTeamId: Value(battingTeam), bowlingTeamId: Value(bowlingTeam),
      openingStrikerId: Value(striker), openingNonStrikerId: Value(nonStriker), openingBowlerId: Value(bowler), oversPerInnings: Value(row['overs_per_innings'] as int),
      ballsPerOver: Value(row['balls_per_over'] as int), twoBowlerMode: Value(_bool(row['two_bowler_mode'])), status: Value(status),
      startedAt: Value(_date(row['started_at'])), completedAt: Value(_date(row['completed_at'])),
    ));
    await _saveIdentity('innings', id, syncId);
    return id;
  }

  Future<void> _importBallEvent(Map<String, dynamic> row, Map<String, int> innings, Map<String, String> playerSourceToSync, Map<String, int> players) async {
    final syncId = _required(row, 'sync_id');
    final inningsId = _resolve(innings, row['innings_sync_id'], 'innings');
    final bowler = _resolveSourceLocal(players, playerSourceToSync, row['bowler_id'], row, 'player');
    final striker = _resolveSourceLocal(players, playerSourceToSync, row['striker_id'], row, 'player');
    final nonStriker = _resolveSourceLocal(players, playerSourceToSync, row['non_striker_id'], row, 'player');
    final existing = await _identityLocalId('ball', syncId);
    if (existing != null) {
      final local = await (_db.select(_db.ballEvents)..where((b) => b.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing ball $existing.');
      await _compareBall(local, row, inningsId, bowler, striker, nonStriker, playerSourceToSync, players); return;
    }
    final duplicate = await (_db.select(_db.ballEvents)..where((b) => b.inningsId.equals(inningsId) & b.sequenceNumber.equals(row['sequence_number'] as int))).getSingleOrNull();
    if (duplicate != null) throw StateError('Recovery divergence: innings $inningsId sequence ${row['sequence_number']} already exists locally.');
    final dismissed = _nullableSourcePlayer(row['dismissed_player_id'], row, playerSourceToSync, players);
    final fielder = _nullableSourcePlayer(row['fielder_id'], row, playerSourceToSync, players);
    final replacement = _nullableSourcePlayer(row['replacement_batter_id'], row, playerSourceToSync, players);
    final id = await _db.into(_db.ballEvents).insert(db.BallEventsCompanion(
      inningsId: Value(inningsId), sequenceNumber: Value(row['sequence_number'] as int), overNumber: Value(row['over_number'] as int), legalBallNumber: Value(row['legal_ball_number'] as int),
      bowlerId: Value(bowler), strikerId: Value(striker), nonStrikerId: Value(nonStriker), deliveryType: Value(row['delivery_type'] as int), isLegalBall: Value(_bool(row['is_legal_ball'])),
      batterRuns: Value(row['batter_runs'] as int), byeRuns: Value(row['bye_runs'] as int), legByeRuns: Value(row['leg_bye_runs'] as int), wideRuns: Value(row['wide_runs'] as int), noBallRuns: Value(row['no_ball_runs'] as int), totalRuns: Value(row['total_runs'] as int),
      wicketType: Value(row['wicket_type'] as int?), dismissedPlayerId: Value(dismissed), fielderId: Value(fielder), runOutEnd: Value(row['run_out_end'] as int?), creditedToBowler: Value(row['credited_to_bowler'] as bool?), timestamp: Value(DateTime.parse(_required(row, 'event_timestamp')).toLocal()),
    ));
    if (row['wicket_type'] != null) {
      await _db.customStatement('INSERT INTO wicket_event_contexts (ball_event_id, completed_runs, crossed_before_wicket, replacement_batter_id) VALUES (?, ?, ?, ?)', [id, row['wicket_completed_runs'] as int? ?? 0, _bool(row['wicket_crossed_before_wicket']) ? 1 : 0, replacement]);
    }
    await _saveIdentity('ball', id, syncId);
    final inserted = await (_db.select(_db.ballEvents)..where((b) => b.id.equals(id))).getSingle();
    await _compareBall(inserted, row, inningsId, bowler, striker, nonStriker, playerSourceToSync, players);
  }

  Future<void> _compareBall(db.BallEvent local, Map<String, dynamic> row, int inningsId, int bowler, int striker, int nonStriker, Map<String, String> playerSourceToSync, Map<String, int> players) async {
    final values = <String, Object?>{
      'innings': local.inningsId, 'sequence': local.sequenceNumber, 'over': local.overNumber, 'legal_ball': local.legalBallNumber,
      'bowler': local.bowlerId, 'striker': local.strikerId, 'non_striker': local.nonStrikerId, 'delivery_type': local.deliveryType, 'is_legal_ball': local.isLegalBall,
      'batter_runs': local.batterRuns, 'bye_runs': local.byeRuns, 'leg_bye_runs': local.legByeRuns, 'wide_runs': local.wideRuns, 'no_ball_runs': local.noBallRuns, 'total_runs': local.totalRuns,
      'wicket_type': local.wicketType, 'dismissed_player_id': local.dismissedPlayerId, 'fielder_id': local.fielderId, 'run_out_end': local.runOutEnd, 'credited_to_bowler': local.creditedToBowler,
    };
    final remote = <String, Object?>{
      'innings': inningsId, 'sequence': row['sequence_number'], 'over': row['over_number'], 'legal_ball': row['legal_ball_number'], 'bowler': bowler, 'striker': striker, 'non_striker': nonStriker,
      'delivery_type': row['delivery_type'], 'is_legal_ball': _bool(row['is_legal_ball']), 'batter_runs': row['batter_runs'], 'bye_runs': row['bye_runs'], 'leg_bye_runs': row['leg_bye_runs'], 'wide_runs': row['wide_runs'], 'no_ball_runs': row['no_ball_runs'], 'total_runs': row['total_runs'],
      'wicket_type': row['wicket_type'], 'dismissed_player_id': _nullableSourcePlayer(row['dismissed_player_id'], row, playerSourceToSync, players), 'fielder_id': _nullableSourcePlayer(row['fielder_id'], row, playerSourceToSync, players), 'run_out_end': row['run_out_end'], 'credited_to_bowler': row['credited_to_bowler'],
    };
    for (final key in values.keys) _eq('ball ${row['sync_id']} $key', values[key], remote[key]);
    _eq('ball ${row['sync_id']} timestamp', local.timestamp.toUtc(), DateTime.parse(_required(row, 'event_timestamp')).toUtc());
    if (row['wicket_type'] != null) {
      final context = await _db.customSelect('SELECT completed_runs, crossed_before_wicket, replacement_batter_id FROM wicket_event_contexts WHERE ball_event_id = ?', variables: [Variable.withInt(local.id)]).getSingleOrNull();
      if (context == null) throw StateError('Recovery divergence: wicket context missing for ball ${local.id}.');
      _eq('wicket completed_runs', context.data['completed_runs'], row['wicket_completed_runs'] ?? 0);
      _eq('wicket crossed_before_wicket', context.data['crossed_before_wicket'] != 0, _bool(row['wicket_crossed_before_wicket']));
      _eq('wicket replacement_batter_id', context.data['replacement_batter_id'], _nullableSourcePlayer(row['replacement_batter_id'], row, playerSourceToSync, players));
    }
  }

  Map<String, String> _sourceMap(List<Map<String, dynamic>> rows) => {
    for (final row in rows) _sourceKey(row['source_installation_id'], row['local_id']): _required(row, 'sync_id'),
  };
  String _sourceKey(dynamic source, dynamic localId) => '${source ?? ''}:$localId';

  int _resolveSourceLocal(Map<String, int> localBySync, Map<String, String> sourceToSync, dynamic remoteLocalId, Map<String, dynamic> referenceRow, String type) {
    final source = referenceRow['source_installation_id']?.toString();
    if (source == null || remoteLocalId == null) throw StateError('Recovery $type reference is missing source_installation_id/local_id.');
    final syncId = sourceToSync[_sourceKey(source, remoteLocalId)];
    if (syncId == null) throw StateError('Recovery cannot resolve $type $source/$remoteLocalId.');
    return _resolve(localBySync, syncId, type);
  }

  int? _nullableSourcePlayer(dynamic value, Map<String, dynamic> row, Map<String, String> sourceToSync, Map<String, int> localBySync) => value == null ? null : _resolveSourceLocal(localBySync, sourceToSync, value, row, 'player');

  Future<int?> _identityLocalId(String type, String syncId) async {
    final rows = await _db.customSelect('SELECT local_id FROM sync_entity_identities WHERE entity_type = ? AND sync_id = ? LIMIT 1', variables: [Variable.withString(type), Variable.withString(syncId)]).get();
    return rows.isEmpty ? null : rows.single.data['local_id'] as int;
  }

  Future<void> _saveIdentity(String type, int localId, String syncId) async {
    final collision = await _db.customSelect('SELECT entity_type, local_id FROM sync_entity_identities WHERE sync_id = ? LIMIT 1', variables: [Variable.withString(syncId)]).getSingleOrNull();
    if (collision != null && (collision.data['entity_type'] != type || collision.data['local_id'] != localId)) throw StateError('Recovery divergence: sync ID $syncId is already assigned to another local entity.');
    await _db.customStatement('INSERT INTO sync_entity_identities(entity_type, local_id, sync_id, created_at) VALUES (?, ?, ?, ?) ON CONFLICT(entity_type, local_id) DO NOTHING', [type, localId, syncId, DateTime.now().toIso8601String()]);
  }

  int _resolve(Map<String, int> map, dynamic key, String type) {
    final value = map[key?.toString()];
    if (value == null) throw StateError('Recovery references unknown $type sync ID $key.');
    return value;
  }

  int _inningsStatus(String status) => switch (status) { 'setup' => 0, 'live' => 1, 'completed' => 2, 'ended' => 3, _ => throw StateError('Unknown recovered innings status $status.') };
  DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
  String _required(Map<String, dynamic> row, String key) { final value = row[key]; if (value == null || value.toString().isEmpty) throw StateError('Recovery row is missing $key.'); return value.toString(); }
  bool _bool(dynamic value) => value == true || value == 1;
  void _eq(String field, Object? local, Object? remote) { if (local != remote) throw StateError('Recovery divergence: $field local=$local remote=$remote'); }

  void _validateSnapshot(RemoteMatchSnapshot snapshot) {
    if (snapshot.match['sync_id'] == null) throw StateError('Recovery snapshot has no match sync ID.');
    if (snapshot.match['innings_count'] != 2 && snapshot.match['innings_count'] != 4) throw StateError('Recovery snapshot has invalid innings count.');
    if (snapshot.match['balls_per_over'] != 6) throw StateError('Recovery snapshot violates fixed six-ball overs.');
    if (snapshot.matchTeams.length != 2) throw StateError('Recovery snapshot must contain exactly two match teams.');
    if (snapshot.innings.length > snapshot.match['innings_count']) throw StateError('Recovery snapshot contains too many innings.');
  }
}
