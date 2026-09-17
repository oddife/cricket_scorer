import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/sync_identity_repository.dart';
import '../../data/repositories/team_player_repository.dart';
import '../../data/repositories/tournament_points_repository.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../data/repositories/tournament_team_repository.dart';
import 'supabase_team_player_transport.dart';
import 'supabase_tournament_transport.dart';

class CatalogPullResult {
  const CatalogPullResult({
    required this.teams,
    required this.players,
    required this.memberships,
    required this.tournaments,
    required this.tournamentTeams,
    required this.pointsRules,
  });

  final int teams;
  final int players;
  final int memberships;
  final int tournaments;
  final int tournamentTeams;
  final int pointsRules;
}

/// Imports the complete global catalog from Supabase into the local Drift DB.
///
/// Server rows are authoritative for catalog distribution. Existing local
/// rows are matched by stable sync identity so a device never creates a
/// duplicate global team or player merely because it is pulling the catalog.
class CatalogPullRepository {
  const CatalogPullRepository(
    this._db,
    this._identity,
    this._teamPlayerTransport,
    this._tournamentTransport,
  );

  final AppDatabase _db;
  final SyncIdentityRepository _identity;
  final SupabaseTeamPlayerTransport _teamPlayerTransport;
  final SupabaseTournamentTransport _tournamentTransport;

  Future<CatalogPullResult> pull() async {
    final remote = await _teamPlayerTransport.downloadCatalog();
    final tournaments = await _tournamentTransport.downloadCatalog();

    return _db.transaction(() async {
      var teams = 0;
      var players = 0;
      var memberships = 0;
      var tournamentCount = 0;
      var tournamentTeams = 0;
      var pointsRules = 0;

      final teamIds = <String, int>{};
      for (final row in remote.teams) {
        teamIds[_required(row, 'sync_id')] = await _upsertTeam(row);
        teams++;
      }

      final playerIds = <String, int>{};
      for (final row in remote.players) {
        playerIds[_required(row, 'sync_id')] = await _upsertPlayer(row);
        players++;
      }

      for (final row in remote.teamPlayers) {
        await _upsertMembership(row, teamIds, playerIds);
        memberships++;
      }

      final tournamentIds = <String, int>{};
      for (final row in tournaments.tournaments) {
        tournamentIds[_required(row, 'sync_id')] = await _upsertTournament(row);
        tournamentCount++;
      }

      for (final row in tournaments.tournamentTeams) {
        await _upsertTournamentTeam(row, tournamentIds, teamIds);
        tournamentTeams++;
      }

      for (final row in tournaments.pointsRules) {
        await _upsertPointsRules(row, tournamentIds);
        pointsRules++;
      }

      return CatalogPullResult(
        teams: teams,
        players: players,
        memberships: memberships,
        tournaments: tournamentCount,
        tournamentTeams: tournamentTeams,
        pointsRules: pointsRules,
      );
    });
  }

  Future<int> _upsertTeam(Map<String, dynamic> row) async {
    final syncId = _required(row, 'sync_id');
    final existing = await _identity.getLocalId('team', syncId);
    final values = TeamsCompanion(
      name: Value(_required(row, 'name')),
      shortName: Value(_required(row, 'short_name')),
      logoPath: Value(row['logo_path'] as String?),
      isActive: Value(_bool(row['is_active'])),
      updatedAt: Value(_date(row['updated_at']) ?? DateTime.now()),
    );
    if (existing != null) {
      await (_db.update(_db.teams)..where((t) => t.id.equals(existing))).write(values);
      return existing;
    }
    final id = await _db.into(_db.teams).insert(TeamsCompanion.insert(
      name: _required(row, 'name'),
      shortName: _required(row, 'short_name'),
      logoPath: Value(row['logo_path'] as String?),
      isActive: Value(_bool(row['is_active'])),
      createdAt: _date(row['created_at']) ?? DateTime.now(),
      updatedAt: _date(row['updated_at']) ?? DateTime.now(),
    ));
    await _identity.saveIdentity('team', id, syncId);
    return id;
  }

  Future<int> _upsertPlayer(Map<String, dynamic> row) async {
    final syncId = _required(row, 'sync_id');
    final existing = await _identity.getLocalId('player', syncId);
    final values = PlayersCompanion(
      name: Value(_required(row, 'name')),
      displayName: Value(_required(row, 'display_name')),
      photoPath: Value(row['photo_path'] as String?),
      jerseyNumber: Value(row['jersey_number'] as int?),
      battingStyle: Value(row['batting_style'] as int),
      bowlingStyle: Value(row['bowling_style'] as int),
      isActive: Value(_bool(row['is_active'])),
      updatedAt: Value(_date(row['updated_at']) ?? DateTime.now()),
    );
    if (existing != null) {
      await (_db.update(_db.players)..where((p) => p.id.equals(existing))).write(values);
      return existing;
    }
    final id = await _db.into(_db.players).insert(PlayersCompanion.insert(
      name: _required(row, 'name'),
      displayName: _required(row, 'display_name'),
      photoPath: Value(row['photo_path'] as String?),
      jerseyNumber: Value(row['jersey_number'] as int?),
      battingStyle: Value(row['batting_style'] as int),
      bowlingStyle: Value(row['bowling_style'] as int),
      isActive: Value(_bool(row['is_active'])),
      createdAt: _date(row['created_at']) ?? DateTime.now(),
      updatedAt: _date(row['updated_at']) ?? DateTime.now(),
    ));
    await _identity.saveIdentity('player', id, syncId);
    return id;
  }

  Future<void> _upsertMembership(
    Map<String, dynamic> row,
    Map<String, int> teams,
    Map<String, int> players,
  ) async {
    final syncId = _required(row, 'sync_id');
    final teamId = _resolve(teams, row['team_sync_id'], 'team');
    final playerId = _resolve(players, row['player_sync_id'], 'player');
    final existing = await _identity.getLocalId('team_player', syncId);
    final values = TeamPlayersCompanion(
      teamId: Value(teamId),
      playerId: Value(playerId),
      jerseyNumber: Value(row['jersey_number'] as int?),
      isActive: Value(_bool(row['is_active'])),
    );
    if (existing != null) {
      await (_db.update(_db.teamPlayers)..where((m) => m.id.equals(existing))).write(values);
      return;
    }
    final id = await _db.into(_db.teamPlayers).insert(TeamPlayersCompanion.insert(
      teamId: teamId,
      playerId: playerId,
      jerseyNumber: Value(row['jersey_number'] as int?),
      isActive: Value(_bool(row['is_active'])),
      createdAt: _date(row['created_at']) ?? DateTime.now(),
    ));
    await _identity.saveIdentity('team_player', id, syncId);
  }

  Future<int> _upsertTournament(Map<String, dynamic> row) async {
    final syncId = _required(row, 'sync_id');
    final existing = await _identity.getLocalId('tournament', syncId);
    final values = TournamentsCompanion(
      name: Value(_required(row, 'name')),
      tournamentType: Value(row['tournament_type'] as int),
      logoPath: Value(row['logo_path'] as String?),
      startDate: Value(_date(row['start_date'])),
      endDate: Value(_date(row['end_date'])),
      isActive: Value(_bool(row['is_active'])),
      updatedAt: Value(_date(row['updated_at']) ?? DateTime.now()),
    );
    if (existing != null) {
      await (_db.update(_db.tournaments)..where((t) => t.id.equals(existing))).write(values);
      return existing;
    }
    final id = await _db.into(_db.tournaments).insert(TournamentsCompanion.insert(
      name: _required(row, 'name'),
      tournamentType: row['tournament_type'] as int,
      logoPath: Value(row['logo_path'] as String?),
      startDate: Value(_date(row['start_date'])),
      endDate: Value(_date(row['end_date'])),
      isActive: Value(_bool(row['is_active'])),
      createdAt: _date(row['created_at']) ?? DateTime.now(),
      updatedAt: _date(row['updated_at']) ?? DateTime.now(),
    ));
    await _identity.saveIdentity('tournament', id, syncId);
    return id;
  }

  Future<void> _upsertTournamentTeam(
    Map<String, dynamic> row,
    Map<String, int> tournaments,
    Map<String, int> teams,
  ) async {
    final tournamentId = _resolve(tournaments, row['tournament_sync_id'], 'tournament');
    final teamId = _resolve(teams, row['team_sync_id'], 'team');
    final existing = await (_db.select(_db.tournamentTeams)
          ..where((t) => t.tournamentId.equals(tournamentId) & t.teamId.equals(teamId)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.tournamentTeams).insert(TournamentTeamsCompanion.insert(
        tournamentId: tournamentId,
        teamId: teamId,
        createdAt: _date(row['created_at']) ?? DateTime.now(),
      ));
    }
  }

  Future<void> _upsertPointsRules(
    Map<String, dynamic> row,
    Map<String, int> tournaments,
  ) async {
    final tournamentId = _resolve(tournaments, row['tournament_sync_id'], 'tournament');
    await _db.customStatement('''
      INSERT INTO tournament_points_rules
        (tournament_id, win_points, tie_points, no_result_points, loss_points)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(tournament_id) DO UPDATE SET
        win_points = excluded.win_points,
        tie_points = excluded.tie_points,
        no_result_points = excluded.no_result_points,
        loss_points = excluded.loss_points
      ''', [
      tournamentId,
      row['win_points'] as int,
      row['tie_points'] as int,
      row['no_result_points'] as int,
      row['loss_points'] as int,
    ]);
  }

  int _resolve(Map<String, int> map, Object? value, String type) {
    final key = value?.toString();
    final id = key == null ? null : map[key];
    if (id == null) throw StateError('Catalog $type $key was not downloaded.');
    return id;
  }

  String _required(Map<String, dynamic> row, String key) {
    final value = row[key]?.toString();
    if (value == null || value.isEmpty) throw StateError('Catalog row is missing $key.');
    return value;
  }

  bool _bool(Object? value) => value == true || value == 1 || value == 'true';
  DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString());
}
