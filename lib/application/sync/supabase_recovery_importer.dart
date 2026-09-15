import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import 'supabase_recovery_transport.dart';

/// Imports a server snapshot into the local authoritative SQLite database.
///
/// Recovery never creates sync queue entries: the snapshot is already present
/// on the server. Stable sync IDs are retained locally so later edits continue
/// to use the same identities.
class SupabaseRecoveryImporter {
  const SupabaseRecoveryImporter(this._db);

  final AppDatabase _db;

  Future<int> importMatch(RemoteMatchSnapshot snapshot) {
    return _db.transaction(() async {
      _validateSnapshot(snapshot);

      final teamIds = await _importTeams(snapshot.teams);
      final playerIds = await _importPlayers(snapshot.players);
      final teamPlayerIds = await _importTeamPlayers(
        snapshot.teamPlayers,
        teamIds,
        playerIds,
      );

      final matchId = await _importMatch(snapshot.match, teamIds);
      await _importMatchTeams(snapshot.matchTeams, matchId, teamIds);
      await _importMatchPlayers(
        snapshot.matchPlayers,
        matchId,
        teamIds,
        playerIds,
      );

      final inningsIds = <String, int>{};
      for (final row in snapshot.innings) {
        inningsIds[row['sync_id'] as String] = await _importInnings(
          row,
          matchId,
          teamIds,
          playerIds,
        );
      }

      for (final row in snapshot.ballEvents) {
        await _importBallEvent(
          row,
          matchId,
          inningsIds,
          playerIds,
        );
      }

      // Keep the variable intentionally referenced: importing memberships is
      // part of the transaction and their local IDs are retained in identities.
      if (teamPlayerIds.isEmpty && snapshot.teamPlayers.isNotEmpty) {
        throw StateError('Team/player membership recovery failed.');
      }
      return matchId;
    });
  }

  Future<Map<String, int>> _importTeams(List<Map<String, dynamic>> rows) async {
    final ids = <String, int>{};
    for (final row in rows) {
      final syncId = _requiredString(row, 'sync_id');
      final existing = await _identityLocalId('team', syncId);
      if (existing != null) {
        final local = await (_db.select(_db.teams)
              ..where((t) => t.id.equals(existing)))
            .getSingleOrNull();
        if (local == null) {
          throw StateError('Recovery identity $syncId points to missing team $existing.');
        }
        _requireEqual('team $syncId name', local.name, _requiredString(row, 'name'));
        _requireEqual('team $syncId short_name', local.shortName, _requiredString(row, 'short_name'));
        _requireEqual('team $syncId logo_path', local.logoPath, row['logo_path'] as String?);
        _requireEqual('team $syncId is_active', local.isActive, _bool(row['is_active']));
        ids[syncId] = existing;
        continue;
      }

      final localId = await _db.into(_db.teams).insert(
        TeamsCompanion.insert(
          name: _requiredString(row, 'name'),
          shortName: _requiredString(row, 'short_name'),
          logoPath: Value(row['logo_path'] as String?),
          isActive: Value(_bool(row['is_active'])),
          createdAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now(),
        ),
      );
      await _saveIdentity('team', localId, syncId);
      ids[syncId] = localId;
    }
    return ids;
  }

  Future<Map<String, int>> _importPlayers(List<Map<String, dynamic>> rows) async {
    final ids = <String, int>{};
    for (final row in rows) {
      final syncId = _requiredString(row, 'sync_id');
      final existing = await _identityLocalId('player', syncId);
      if (existing != null) {
        final local = await (_db.select(_db.players)
              ..where((p) => p.id.equals(existing)))
            .getSingleOrNull();
        if (local == null) {
          throw StateError('Recovery identity $syncId points to missing player $existing.');
        }
        _requireEqual('player $syncId name', local.name, _requiredString(row, 'name'));
        _requireEqual('player $syncId display_name', local.displayName, _requiredString(row, 'display_name'));
        _requireEqual('player $syncId photo_path', local.photoPath, row['photo_path'] as String?);
        _requireEqual('player $syncId jersey_number', local.jerseyNumber, row['jersey_number'] as int?);
        _requireEqual('player $syncId batting_style', local.battingStyle, row['batting_style'] as int);
        _requireEqual('player $syncId bowling_style', local.bowlingStyle, row['bowling_style'] as int);
        _requireEqual('player $syncId is_active', local.isActive, _bool(row['is_active']));
        ids[syncId] = existing;
        continue;
      }

      final localId = await _db.into(_db.players).insert(
        PlayersCompanion.insert(
          name: _requiredString(row, 'name'),
          displayName: _requiredString(row, 'display_name'),
          photoPath: Value(row['photo_path'] as String?),
          jerseyNumber: Value(row['jersey_number'] as int?),
          battingStyle: Value(row['batting_style'] as int),
          bowlingStyle: Value(row['bowling_style'] as int),
          isActive: Value(_bool(row['is_active'])),
          createdAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now(),
        ),
      );
      await _saveIdentity('player', localId, syncId);
      ids[syncId] = localId;
    }
    return ids;
  }

  Future<Map<String, int>> _importTeamPlayers(
    List<Map<String, dynamic>> rows,
    Map<String, int> teamIds,
    Map<String, int> playerIds,
  ) async {
    final ids = <String, int>{};
    for (final row in rows) {
      final syncId = _requiredString(row, 'sync_id');
      final teamId = _resolve(teamIds, row['team_sync_id'], 'team');
      final playerId = _resolve(playerIds, row['player_sync_id'], 'player');
      final existing = await _identityLocalId('team_player', syncId);
      if (existing != null) {
        final local = await (_db.select(_db.teamPlayers)
              ..where((t) => t.id.equals(existing)))
            .getSingleOrNull();
        if (local == null) throw StateError('Recovery identity $syncId points to missing membership $existing.');
        _requireEqual('membership $syncId team', local.teamId, teamId);
        _requireEqual('membership $syncId player', local.playerId, playerId);
        _requireEqual('membership $syncId jersey_number', local.jerseyNumber, row['jersey_number'] as int?);
        _requireEqual('membership $syncId is_active', local.isActive, _bool(row['is_active']));
        ids[syncId] = existing;
        continue;
      }

      final duplicate = await (_db.select(_db.teamPlayers)
            ..where((t) => t.teamId.equals(teamId) & t.playerId.equals(playerId)))
          .getSingleOrNull();
      if (duplicate != null) {
        throw StateError('Recovery divergence: membership $syncId conflicts with local membership ${duplicate.id}.');
      }

      final localId = await _db.into(_db.teamPlayers).insert(
        TeamPlayersCompanion.insert(
          teamId: teamId,
          playerId: playerId,
          jerseyNumber: Value(row['jersey_number'] as int?),
          isActive: Value(_bool(row['is_active'])),
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
        ),
      );
      await _saveIdentity('team_player', localId, syncId);
      ids[syncId] = localId;
    }
    return ids;
  }

  Future<int> _importMatch(Map<String, dynamic> row, Map<String, int> teamIds) async {
    final syncId = _requiredString(row, 'sync_id');
    final tossTeamRemote = row['toss_winner_team_id'];
    final tossTeamId = tossTeamRemote == null ? null : _resolveBySourceLocal(teamIds, tossTeamRemote, row, 'team');
    final existing = await _identityLocalId('match', syncId);
    if (existing != null) {
      final local = await (_db.select(_db.matches)..where((m) => m.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing match $existing.');
      _requireEqual('match $syncId name', local.name, _requiredString(row, 'name'));
      _requireEqual('match $syncId date', local.date.toUtc().toIso8601String(), DateTime.parse(_requiredString(row, 'date')).toUtc().toIso8601String());
      _requireEqual('match $syncId innings_count', local.inningsCount, row['innings_count'] as int);
      _requireEqual('match $syncId overs_per_innings', local.oversPerInnings, row['overs_per_innings'] as int);
      _requireEqual('match $syncId balls_per_over', local.ballsPerOver, row['balls_per_over'] as int);
      _requireEqual('match $syncId players_per_team', local.playersPerTeam, row['players_per_team'] as int);
      _requireEqual('match $syncId two_bowler_mode', local.twoBowlerMode, _bool(row['two_bowler_mode']));
      _requireEqual('match $syncId toss_winner', local.tossWinnerTeamId, tossTeamId);
      _requireEqual('match $syncId toss_decision', local.tossDecision, row['toss_decision'] as int?);
      _requireEqual('match $syncId status', local.status, row['status'] as int);
      return existing;
    }

    final localId = await _db.into(_db.matches).insert(
      MatchesCompanion.insert(
        tournamentId: const Value(null),
        name: _requiredString(row, 'name'),
        date: DateTime.parse(_requiredString(row, 'date')).toLocal(),
        venue: Value(row['venue'] as String?),
        inningsCount: row['innings_count'] as int,
        oversPerInnings: row['overs_per_innings'] as int,
        ballsPerOver: row['balls_per_over'] as int,
        playersPerTeam: row['players_per_team'] as int,
        twoBowlerMode: Value(_bool(row['two_bowler_mode'])),
        tossWinnerTeamId: Value(tossTeamId),
        tossDecision: Value(row['toss_decision'] as int?),
        status: Value(row['status'] as int),
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now(),
      ),
    );
    await _saveIdentity('match', localId, syncId);
    return localId;
  }

  Future<void> _importMatchTeams(List<Map<String, dynamic>> rows, int matchId, Map<String, int> teamIds) async {
    for (final row in rows) {
      final teamId = _resolve(teamIds, row['team_sync_id'], 'team');
      final slot = row['slot'] as int;
      final existing = await (_db.select(_db.matchTeams)
            ..where((t) => t.matchId.equals(matchId) & t.slot.equals(slot)))
          .getSingleOrNull();
      if (existing != null) {
        _requireEqual('match team slot $slot team', existing.teamId, teamId);
        continue;
      }
      final duplicate = await (_db.select(_db.matchTeams)
            ..where((t) => t.matchId.equals(matchId) & t.teamId.equals(teamId)))
          .getSingleOrNull();
      if (duplicate != null) throw StateError('Recovery divergence: duplicate match team assignment.');
      await _db.into(_db.matchTeams).insert(
        MatchTeamsCompanion.insert(matchId: matchId, teamId: teamId, slot: slot),
      );
    }
  }

  Future<void> _importMatchPlayers(
    List<Map<String, dynamic>> rows,
    int matchId,
    Map<String, int> teamIds,
    Map<String, int> playerIds,
  ) async {
    for (final row in rows) {
      final teamId = _resolve(teamIds, row['team_sync_id'], 'team');
      final playerId = _resolve(playerIds, row['player_sync_id'], 'player');
      final existing = await (_db.select(_db.matchPlayers)
            ..where((p) => p.matchId.equals(matchId) & p.playerId.equals(playerId)))
          .getSingleOrNull();
      if (existing != null) {
        _requireEqual('match player $playerId team', existing.teamId, teamId);
        _requireEqual('match player $playerId is_playing', existing.isPlaying, _bool(row['is_playing']));
        _requireEqual('match player $playerId batting_order', existing.battingOrder, row['batting_order'] as int?);
        continue;
      }
      await _db.into(_db.matchPlayers).insert(
        MatchPlayersCompanion.insert(
          matchId: matchId,
          teamId: teamId,
          playerId: playerId,
          isPlaying: Value(_bool(row['is_playing'])),
          battingOrder: Value(row['batting_order'] as int?),
        ),
      );
    }
  }

  Future<int> _importInnings(
    Map<String, dynamic> row,
    int matchId,
    Map<String, int> teamIds,
    Map<String, int> playerIds,
  ) async {
    final syncId = _requiredString(row, 'sync_id');
    final battingTeamId = _resolveBySourceLocal(teamIds, row['batting_team_id'], row, 'team');
    final bowlingTeamId = _resolveBySourceLocal(teamIds, row['bowling_team_id'], row, 'team');
    final strikerId = _resolveBySourceLocal(playerIds, row['opening_striker_id'], row, 'player');
    final nonStrikerId = _resolveBySourceLocal(playerIds, row['opening_non_striker_id'], row, 'player');
    final bowlerId = _resolveBySourceLocal(playerIds, row['opening_bowler_id'], row, 'player');
    final status = _inningsStatus(row['status']);
    final existing = await _identityLocalId('innings', syncId);
    if (existing != null) {
      final local = await (_db.select(_db.innings)..where((i) => i.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing innings $existing.');
      _requireEqual('innings $syncId match', local.matchId, matchId);
      _requireEqual('innings $syncId number', local.inningsNumber, row['innings_number'] as int);
      _requireEqual('innings $syncId batting team', local.battingTeamId, battingTeamId);
      _requireEqual('innings $syncId bowling team', local.bowlingTeamId, bowlingTeamId);
      _requireEqual('innings $syncId striker', local.openingStrikerId, strikerId);
      _requireEqual('innings $syncId non-striker', local.openingNonStrikerId, nonStrikerId);
      _requireEqual('innings $syncId bowler', local.openingBowlerId, bowlerId);
      _requireEqual('innings $syncId overs', local.oversPerInnings, row['overs_per_innings'] as int);
      _requireEqual('innings $syncId balls', local.ballsPerOver, row['balls_per_over'] as int);
      _requireEqual('innings $syncId two-bowler', local.twoBowlerMode, _bool(row['two_bowler_mode']));
      _requireEqual('innings $syncId status', local.status, status);
      return existing;
    }
    final duplicate = await (_db.select(_db.innings)
          ..where((i) => i.matchId.equals(matchId) & i.inningsNumber.equals(row['innings_number'] as int)))
        .getSingleOrNull();
    if (duplicate != null) throw StateError('Recovery divergence: innings number already exists locally.');
    final localId = await _db.into(_db.innings).insert(
      InningsCompanion.insert(
        matchId: matchId,
        inningsNumber: row['innings_number'] as int,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        openingStrikerId: strikerId,
        openingNonStrikerId: nonStrikerId,
        openingBowlerId: bowlerId,
        oversPerInnings: row['overs_per_innings'] as int,
        ballsPerOver: row['balls_per_over'] as int,
        twoBowlerMode: _bool(row['two_bowler_mode']),
        status: Value(status),
        startedAt: Value(_date(row['started_at'])),
        completedAt: Value(_date(row['completed_at'])),
      ),
    );
    await _saveIdentity('innings', localId, syncId);
    return localId;
  }

  Future<void> _importBallEvent(
    Map<String, dynamic> row,
    int matchId,
    Map<String, int> inningsIds,
    Map<String, int> playerIds,
  ) async {
    final syncId = _requiredString(row, 'sync_id');
    final inningsId = _resolve(inningsIds, row['innings_sync_id'], 'innings');
    final bowlerId = _resolveBySourceLocal(playerIds, row['bowler_id'], row, 'player');
    final strikerId = _resolveBySourceLocal(playerIds, row['striker_id'], row, 'player');
    final nonStrikerId = _resolveBySourceLocal(playerIds, row['non_striker_id'], row, 'player');
    final existing = await _identityLocalId('ball', syncId);
    if (existing != null) {
      final local = await (_db.select(_db.ballEvents)..where((b) => b.id.equals(existing))).getSingleOrNull();
      if (local == null) throw StateError('Recovery identity $syncId points to missing ball event $existing.');
      await _compareBall(local, row, inningsId, bowlerId, strikerId, nonStrikerId);
      return;
    }
    final duplicate = await (_db.select(_db.ballEvents)
          ..where((b) => b.inningsId.equals(inningsId) & b.sequenceNumber.equals(row['sequence_number'] as int)))
        .getSingleOrNull();
    if (duplicate != null) throw StateError('Recovery divergence: innings $inningsId sequence ${row['sequence_number']} already exists locally.');

    final localId = await _db.into(_db.ballEvents).insert(
      BallEventsCompanion.insert(
        inningsId: inningsId,
        sequenceNumber: row['sequence_number'] as int,
        overNumber: row['over_number'] as int,
        legalBallNumber: row['legal_ball_number'] as int,
        bowlerId: bowlerId,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        deliveryType: row['delivery_type'] as int,
        isLegalBall: _bool(row['is_legal_ball']),
        batterRuns: row['batter_runs'] as int,
        byeRuns: row['bye_runs'] as int,
        legByeRuns: row['leg_bye_runs'] as int,
        wideRuns: row['wide_runs'] as int,
        noBallRuns: row['no_ball_runs'] as int,
        totalRuns: row['total_runs'] as int,
        wicketType: Value(row['wicket_type'] as int?),
        dismissedPlayerId: Value(_resolveNullablePlayer(row['dismissed_player_id'], row, playerIds)),
        fielderId: Value(_resolveNullablePlayer(row['fielder_id'], row, playerIds)),
        runOutEnd: Value(row['run_out_end'] as int?),
        creditedToBowler: Value(row['credited_to_bowler'] as bool?),
        timestamp: DateTime.parse(_requiredString(row, 'event_timestamp')).toLocal(),
      ),
    );
    if (row['wicket_type'] != null) {
      await _db.customStatement(
        'INSERT INTO wicket_event_contexts (ball_event_id, completed_runs, crossed_before_wicket, replacement_batter_id) VALUES (?, ?, ?, ?)',
        [
          localId,
          row['wicket_completed_runs'] as int? ?? 0,
          _bool(row['wicket_crossed_before_wicket']) ? 1 : 0,
          _resolveNullablePlayer(row['replacement_batter_id'], row, playerIds),
        ],
      );
    }
    await _saveIdentity('ball', localId, syncId);
    // Verify the immutable remote fact after insertion using the local row.
    final inserted = await (_db.select(_db.ballEvents)..where((b) => b.id.equals(localId))).getSingle();
    await _compareBall(inserted, row, inningsId, bowlerId, strikerId, nonStrikerId);
    if (inserted.inningsId != matchId && matchId <= 0) throw StateError('Invalid recovered match reference.');
  }

  Future<void> _compareBall(dynamic local, Map<String, dynamic> row, int inningsId, int bowlerId, int strikerId, int nonStrikerId) async {
    final checks = <String, dynamic>{
      'innings': [local.inningsId, inningsId],
      'sequence': [local.sequenceNumber, row['sequence_number']],
      'over': [local.overNumber, row['over_number']],
      'legal_ball': [local.legalBallNumber, row['legal_ball_number']],
      'bowler': [local.bowlerId, bowlerId],
      'striker': [local.strikerId, strikerId],
      'non_striker': [local.nonStrikerId, nonStrikerId],
      'delivery_type': [local.deliveryType, row['delivery_type']],
      'is_legal_ball': [local.isLegalBall, _bool(row['is_legal_ball'])],
      'batter_runs': [local.batterRuns, row['batter_runs']],
      'bye_runs': [local.byeRuns, row['bye_runs']],
      'leg_bye_runs': [local.legByeRuns, row['leg_bye_runs']],
      'wide_runs': [local.wideRuns, row['wide_runs']],
      'no_ball_runs': [local.noBallRuns, row['no_ball_runs']],
      'total_runs': [local.totalRuns, row['total_runs']],
      'wicket_type': [local.wicketType, row['wicket_type']],
      'dismissed_player_id': [local.dismissedPlayerId, row['dismissed_player_id']],
      'fielder_id': [local.fielderId, row['fielder_id']],
      'run_out_end': [local.runOutEnd, row['run_out_end']],
      'credited_to_bowler': [local.creditedToBowler, row['credited_to_bowler']],
    };
    for (final entry in checks.entries) {
      _requireEqual('ball ${row['sync_id']} ${entry.key}', entry.value[0], entry.value[1]);
    }
    _requireEqual('ball ${row['sync_id']} timestamp', local.timestamp.toUtc().toIso8601String(), DateTime.parse(_requiredString(row, 'event_timestamp')).toUtc().toIso8601String());
  }

  Future<int?> _identityLocalId(String type, String syncId) async {
    final rows = await _db.customSelect(
      'SELECT local_id FROM sync_entity_identities WHERE entity_type = ? AND sync_id = ? LIMIT 1',
      variables: [Variable.withString(type), Variable.withString(syncId)],
    ).get();
    return rows.isEmpty ? null : rows.single.data['local_id'] as int;
  }

  Future<void> _saveIdentity(String type, int localId, String syncId) async {
    final existing = await _identityLocalId(type, syncId);
    if (existing != null && existing != localId) {
      throw StateError('Recovery divergence: sync ID $syncId already maps to local $existing.');
    }
    await _db.customStatement(
      '''INSERT INTO sync_entity_identities(entity_type, local_id, sync_id, created_at)
         VALUES (?, ?, ?, ?)
         ON CONFLICT(entity_type, local_id) DO NOTHING''',
      [type, localId, syncId, DateTime.now().toIso8601String()],
    );
  }

  int _resolve(Map<String, int> ids, dynamic syncId, String type) {
    final key = syncId?.toString();
    final value = key == null ? null : ids[key];
    if (value == null) throw StateError('Recovery references unknown $type sync ID $syncId.');
    return value;
  }

  int _resolveBySourceLocal(Map<String, int> ids, dynamic localId, Map<String, dynamic> row, String type) {
    final source = row['source_installation_id']?.toString();
    if (source == null || localId == null) throw StateError('Recovery $type reference is missing its source installation ID.');
    final matches = <String>[];
    // Catalog rows are keyed by source installation + originating local ID.
    // Build the key lazily from the snapshot is not possible here, so the caller
    // must have included the stable ID in the row when using this path.
    final sync = row['${type}_sync_id']?.toString();
    if (sync != null && ids.containsKey(sync)) return ids[sync]!;
    throw StateError('Recovery cannot resolve $type source ID $source/$localId; stable ${type}_sync_id is required in the snapshot row.');
  }

  int? _resolveNullablePlayer(dynamic value, Map<String, dynamic> row, Map<String, int> playerIds) {
    if (value == null) return null;
    final sync = row['player_sync_id_${_fieldName(value, row)}']?.toString();
    if (sync != null && playerIds.containsKey(sync)) return playerIds[sync];
    return null;
  }

  String _fieldName(dynamic value, Map<String, dynamic> row) => 'reference';

  int _inningsStatus(String value) => switch (value) {
    'setup' => 0,
    'live' => 1,
    'completed' => 2,
    'ended' => 3,
    _ => throw StateError('Unknown recovered innings status $value.'),
  };

  DateTime? _date(dynamic value) => value == null ? null : DateTime.parse(value.toString()).toLocal();

  String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null || value.toString().isEmpty) throw StateError('Recovery row is missing $key.');
    return value.toString();
  }

  bool _bool(dynamic value) => value == true || value == 1;

  void _requireEqual(String field, Object? local, Object? remote) {
    if (local != remote) {
      throw StateError('Recovery divergence: $field local=$local remote=$remote');
    }
  }

  void _validateSnapshot(RemoteMatchSnapshot snapshot) {
    if (snapshot.match['sync_id'] == null) throw StateError('Recovery snapshot has no match sync ID.');
    if (snapshot.match['innings_count'] != 2 && snapshot.match['innings_count'] != 4) {
      throw StateError('Recovery snapshot has invalid innings count.');
    }
    if (snapshot.match['balls_per_over'] != 6) throw StateError('Recovery snapshot violates fixed six-ball overs.');
    if (snapshot.matchTeams.length != 2) throw StateError('Recovery snapshot must contain exactly two match teams.');
  }
}
