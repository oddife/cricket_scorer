import 'package:drift/drift.dart';

import '../../domain/players/enums/batting_style.dart';
import '../../domain/players/enums/bowling_style.dart';
import '../../domain/players/models/player.dart' as domain;
import '../../domain/teams/models/team_player.dart';
import '../database/app_database.dart' hide TeamPlayer;
import 'team_player_repository.dart';

class DriftTeamPlayerRepository implements TeamPlayerRepository {
  DriftTeamPlayerRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Player>> getPlayersForTeam(int teamId) async {
    final query = _database.select(_database.players).join([
      innerJoin(
        _database.teamPlayers,
        _database.teamPlayers.playerId.equalsExp(_database.players.id),
      ),
    ])
      ..where(
        _database.teamPlayers.teamId.equals(teamId) &
            _database.teamPlayers.isActive.equals(true) &
            _database.players.isActive.equals(true),
      )
      ..orderBy([
        OrderingTerm.asc(_database.teamPlayers.jerseyNumber),
        OrderingTerm.asc(_database.players.displayName),
      ]);

    final rows = await query.get();
    return rows
        .map((row) => _toPlayer(row.readTable(_database.players)))
        .toList(growable: false);
  }

  @override
  Future<TeamPlayer> addPlayerToTeam({
    required int teamId,
    required int playerId,
    int? jerseyNumber,
  }) async {
    final existing = await (_database.select(_database.teamPlayers)
          ..where(
            (row) => row.teamId.equals(teamId) & row.playerId.equals(playerId),
          ))
        .getSingleOrNull();

    if (existing != null) {
      if (!existing.isActive) {
        await (_database.update(_database.teamPlayers)
              ..where((row) => row.id.equals(existing.id)))
            .write(
          TeamPlayersCompanion(
            jerseyNumber: Value(jerseyNumber),
            isActive: const Value(true),
          ),
        );
        return TeamPlayer(
          id: existing.id,
          teamId: teamId,
          playerId: playerId,
          jerseyNumber: jerseyNumber,
        );
      }
      throw StateError('Player is already a member of this team.');
    }

    final id = await _database.into(_database.teamPlayers).insert(
          TeamPlayersCompanion.insert(
            teamId: teamId,
            playerId: playerId,
            jerseyNumber: Value(jerseyNumber),
            isActive: const Value(true),
            createdAt: DateTime.now(),
          ),
        );

    return TeamPlayer(
      id: id,
      teamId: teamId,
      playerId: playerId,
      jerseyNumber: jerseyNumber,
    );
  }

  @override
  Future<void> removePlayerFromTeam(int teamId, int playerId) async {
    await (_database.update(_database.teamPlayers)
          ..where(
            (row) => row.teamId.equals(teamId) & row.playerId.equals(playerId),
          ))
        .write(const TeamPlayersCompanion(isActive: Value(false)));
  }

  @override
  Future<void> updateJerseyNumber(
    int teamId,
    int playerId,
    int? jerseyNumber,
  ) async {
    await (_database.update(_database.teamPlayers)
          ..where(
            (row) => row.teamId.equals(teamId) & row.playerId.equals(playerId),
          ))
        .write(TeamPlayersCompanion(jerseyNumber: Value(jerseyNumber)));
  }

  domain.Player _toPlayer(Player row) {
    return domain.Player(
      id: row.id,
      name: row.name,
      displayName: row.displayName,
      photoPath: row.photoPath,
      jerseyNumber: row.jerseyNumber,
      battingStyle: battingStyleFromDbValue(row.battingStyle),
      bowlingStyle: bowlingStyleFromDbValue(row.bowlingStyle),
      isActive: row.isActive,
    );
  }
}
