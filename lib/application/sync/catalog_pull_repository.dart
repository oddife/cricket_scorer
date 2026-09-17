import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import 'supabase_catalog_pull_transport.dart';

class CatalogPullResult {
  const CatalogPullResult({
    required this.teams,
    required this.players,
    required this.teamPlayers,
    required this.tournaments,
    required this.tournamentTeams,
    required this.pointsRules,
  });

  final int teams;
  final int players;
  final int teamPlayers;
  final int tournaments;
  final int tournamentTeams;
  final int pointsRules;

  int get total =>
      teams + players + teamPlayers + tournaments + tournamentTeams + pointsRules;
}

/// Imports the complete shared catalog into local Drift/SQLite.
///
/// Downloaded rows are written directly to Drift, so they are deliberately
/// not placed on the upload queue. Local scoring remains authoritative and the
/// normal catalog upload phase still runs before this pull on each sync cycle.
class CatalogPullRepository {
  const CatalogPullRepository(this._database, this._transport);

  final AppDatabase _database;
  final SupabaseCatalogPullTransport _transport;

  Future<CatalogPullResult> pull() async {
    final teams = await _transport.downloadTeams();
    final players = await _transport.downloadPlayers();
    final teamPlayers = await _transport.downloadTeamPlayers();
    final tournaments = await _transport.downloadTournaments();
    final tournamentTeams = await _transport.downloadTournamentTeams();
    final pointsRules = await _transport.downloadPointsRules();

    return _database.transaction(() async {
      final teamCount = await _importTeams(teams);
      final playerCount = await _importPlayers(players);
      final teamPlayerCount = await _importTeamPlayers(teamPlayers);
      final tournamentCount = await _importTournaments(tournaments);
      final tournamentTeamCount = await _importTournamentTeams(tournamentTeams);
      final rulesCount = await _importPointsRules(pointsRules);

      return CatalogPullResult(
        teams: teamCount,
        players: playerCount,
        teamPlayers: teamPlayerCount,
        tournaments: tournamentCount,
        tournamentTeams: tournamentTeamCount,
        pointsRules: rulesCount,
      );
    });
  }

  Future<int> _importTeams(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final syncId = _requiredString(row, 'sync_id');
      final existingId = await _localIdForSync('team', syncId);
      final now = DateTime.now();
      if (existingId != null) {
        await (_database.update(_database.teams)
              ..where((table) => table.id.equals(existingId)))
            .write(
          TeamsCompanion(
            name: Value(_requiredString(row, 'name')),
            shortName: Value(_requiredString(row, 'short_name')),
            logoPath: Value(row['logo_path'] as String?),
            isActive: Value(_bool(row, 'is_active', true)),
            updatedAt: Value(now),
          ),
        );
      } else {
        final id = await _database.into(_database.teams).insert(
              TeamsCompanion.insert(
                name: _requiredString(row, 'name'),
                shortName: _requiredString(row, 'short_name'),
                logoPath: Value(row['logo_path'] as String?),
                isActive: Value(_bool(row, 'is_active', true)),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _rememberIdentity('team', id, syncId);
      }
    }
    return rows.length;
  }

  Future<int> _importPlayers(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final syncId = _requiredString(row, 'sync_id');
      final existingId = await _localIdForSync('player', syncId);
      final now = DateTime.now();
      if (existingId != null) {
        await (_database.update(_database.players)
              ..where((table) => table.id.equals(existingId)))
            .write(
          PlayersCompanion(
            name: Value(_requiredString(row, 'name')),
            displayName: Value(_requiredString(row, 'display_name')),
            photoPath: Value(row['photo_path'] as String?),
            jerseyNumber: Value(_intOrNull(row['jersey_number'])),
            battingStyle: Value(_intOrDefault(row, 'batting_style', 0)),
            bowlingStyle: Value(_intOrDefault(row, 'bowling_style', 0)),
            isActive: Value(_bool(row, 'is_active', true)),
            updatedAt: Value(now),
          ),
        );
      } else {
        final id = await _database.into(_database.players).insert(
              PlayersCompanion.insert(
                name: _requiredString(row, 'name'),
                displayName: _requiredString(row, 'display_name'),
                photoPath: Value(row['photo_path'] as String?),
                jerseyNumber: Value(_intOrNull(row['jersey_number'])),
                battingStyle: Value(_intOrDefault(row, 'batting_style', 0)),
                bowlingStyle: Value(_intOrDefault(row, 'bowling_style', 0)),
                isActive: Value(_bool(row, 'is_active', true)),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _rememberIdentity('player', id, syncId);
      }
    }
    return rows.length;
  }

  Future<int> _importTeamPlayers(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final syncId = _requiredString(row, 'sync_id');
      final teamId = await _localIdForSync(
        'team',
        _requiredString(row, 'team_sync_id'),
      );
      final playerId = await _localIdForSync(
        'player',
        _requiredString(row, 'player_sync_id'),
      );
      if (teamId == null || playerId == null) {
        throw StateError(
          'Cannot import team_player $syncId: referenced team/player is missing.',
        );
      }

      final existingId = await _localIdForSync('team_player', syncId);
      final existingMembership = await (_database.select(_database.teamPlayers)
            ..where(
              (table) =>
                  table.teamId.equals(teamId) & table.playerId.equals(playerId),
            ))
          .getSingleOrNull();

      if (existingId != null) {
        if (existingMembership != null && existingMembership.id != existingId) {
          throw StateError('Team-player membership $syncId conflicts with local membership.');
        }
        await (_database.update(_database.teamPlayers)
              ..where((table) => table.id.equals(existingId)))
            .write(
          TeamPlayersCompanion(
            jerseyNumber: Value(_intOrNull(row['jersey_number'])),
            isActive: Value(_bool(row, 'is_active', true)),
          ),
        );
      } else if (existingMembership != null) {
        await _rememberIdentity('team_player', existingMembership.id, syncId);
        await (_database.update(_database.teamPlayers)
              ..where((table) => table.id.equals(existingMembership.id)))
            .write(
          TeamPlayersCompanion(
            jerseyNumber: Value(_intOrNull(row['jersey_number'])),
            isActive: Value(_bool(row, 'is_active', true)),
          ),
        );
      } else {
        final id = await _database.into(_database.teamPlayers).insert(
              TeamPlayersCompanion.insert(
                teamId: teamId,
                playerId: playerId,
                jerseyNumber: Value(_intOrNull(row['jersey_number'])),
                isActive: Value(_bool(row, 'is_active', true)),
                createdAt: _dateTimeOrNow(row['created_at']),
              ),
            );
        await _rememberIdentity('team_player', id, syncId);
      }
    }
    return rows.length;
  }

  Future<int> _importTournaments(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final syncId = _requiredString(row, 'sync_id');
      final existingId = await _localIdForSync('tournament', syncId);
      final now = DateTime.now();
      final startDate = _dateTimeOrNull(row['start_date']);
      final endDate = _dateTimeOrNull(row['end_date']);
      if (existingId != null) {
        await (_database.update(_database.tournaments)
              ..where((table) => table.id.equals(existingId)))
            .write(
          TournamentsCompanion(
            name: Value(_requiredString(row, 'name')),
            tournamentType: Value(_intOrDefault(row, 'tournament_type', 0)),
            logoPath: Value(row['logo_path'] as String?),
            startDate: Value(startDate),
            endDate: Value(endDate),
            isActive: Value(_bool(row, 'is_active', true)),
            updatedAt: Value(now),
          ),
        );
      } else {
        final id = await _database.into(_database.tournaments).insert(
              TournamentsCompanion.insert(
                name: _requiredString(row, 'name'),
                tournamentType: _intOrDefault(row, 'tournament_type', 0),
                logoPath: Value(row['logo_path'] as String?),
                startDate: Value(startDate),
                endDate: Value(endDate),
                isActive: Value(_bool(row, 'is_active', true)),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _rememberIdentity('tournament', id, syncId);
      }
    }
    return rows.length;
  }

  Future<int> _importTournamentTeams(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final tournamentId = await _localIdForSync(
        'tournament',
        _requiredString(row, 'tournament_sync_id'),
      );
      final teamId = await _localIdForSync(
        'team',
        _requiredString(row, 'team_sync_id'),
      );
      if (tournamentId == null || teamId == null) {
        throw StateError('Cannot import tournament team membership: dependency is missing.');
      }
      await _database.into(_database.tournamentTeams).insertOnConflictUpdate(
            TournamentTeamsCompanion.insert(
              tournamentId: Value(tournamentId),
              teamId: Value(teamId),
              createdAt: _dateTimeOrNow(row['created_at']),
            ),
          );
    }
    return rows.length;
  }

  Future<int> _importPointsRules(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final tournamentId = await _localIdForSync(
        'tournament',
        _requiredString(row, 'tournament_sync_id'),
      );
      if (tournamentId == null) {
        throw StateError('Cannot import tournament points rules: tournament is missing.');
      }
      await _database.customStatement(
        '''INSERT INTO tournament_points_rules
        (tournament_id, win_points, tie_points, no_result_points, loss_points)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(tournament_id) DO UPDATE SET
        win_points = excluded.win_points,
        tie_points = excluded.tie_points,
        no_result_points = excluded.no_result_points,
        loss_points = excluded.loss_points''',
        [
          tournamentId,
          _intOrDefault(row, 'win_points', 2),
          _intOrDefault(row, 'tie_points', 1),
          _intOrDefault(row, 'no_result_points', 1),
          _intOrDefault(row, 'loss_points', 0),
        ],
      );
    }
    return rows.length;
  }

  Future<int?> _localIdForSync(String entityType, String syncId) async {
    final rows = await _database.customSelect(
      '''SELECT local_id FROM sync_entity_identities
         WHERE entity_type = ? AND sync_id = ? LIMIT 1''',
      variables: [
        Variable.withString(entityType),
        Variable.withString(syncId),
      ],
    ).get();
    if (rows.isEmpty) return null;
    return rows.single.read<int>('local_id');
  }

  Future<void> _rememberIdentity(
    String entityType,
    int localId,
    String syncId,
  ) async {
    final bySync = await _database.customSelect(
      '''SELECT entity_type, local_id FROM sync_entity_identities
         WHERE sync_id = ? LIMIT 1''',
      variables: [Variable.withString(syncId)],
    ).get();
    if (bySync.isNotEmpty) {
      final existingType = bySync.single.read<String>('entity_type');
      final existingId = bySync.single.read<int>('local_id');
      if (existingType != entityType || existingId != localId) {
        throw StateError('Sync identity $syncId is already mapped to another local entity.');
      }
      return;
    }

    await _database.customStatement(
      '''INSERT INTO sync_entity_identities
      (entity_type, local_id, sync_id, created_at)
      VALUES (?, ?, ?, ?)''',
      [entityType, localId, syncId, DateTime.now().toIso8601String()],
    );
  }

  String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw StateError('Supabase catalog row is missing required $key.');
  }

  bool _bool(Map<String, dynamic> row, String key, bool fallback) =>
      row[key] is bool ? row[key] as bool : fallback;

  int _intOrDefault(Map<String, dynamic> row, String key, int fallback) =>
      row[key] is int ? row[key] as int : fallback;

  int? _intOrNull(dynamic value) => value is int ? value : null;

  DateTime _dateTimeOrNow(dynamic value) =>
      _dateTimeOrNull(value) ?? DateTime.now();

  DateTime? _dateTimeOrNull(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}
