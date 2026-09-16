import 'package:drift/drift.dart';

import '../../domain/players/enums/batting_style.dart';
import '../../domain/players/enums/bowling_style.dart';
import '../../domain/players/models/player.dart' as domain;
import '../../domain/teams/models/team_player.dart';
import '../database/app_database.dart' hide TeamPlayer;
import 'catalog_sync_queue_repository.dart';
import 'sync_identity_repository.dart';
import 'team_player_repository.dart';

class DriftTeamPlayerRepository implements TeamPlayerRepository {
  DriftTeamPlayerRepository(
    this._database, [
    this._catalogSyncQueueRepository,
    this._syncIdentityRepository,
  ]);

  final AppDatabase _database;
  final CatalogSyncQueueRepository? _catalogSyncQueueRepository;
  final SyncIdentityRepository? _syncIdentityRepository;

  @override
  Future<List<domain.Player>> getPlayersForTeam(int teamId) async {
    final query = _database.select(_database.players).join([
      innerJoin(_database.teamPlayers,
          _database.teamPlayers.playerId.equalsExp(_database.players.id)),
    ])
      ..where(_database.teamPlayers.teamId.equals(teamId) &
          _database.teamPlayers.isActive.equals(true) &
          _database.players.isActive.equals(true))
      ..orderBy([
        OrderingTerm.asc(_database.teamPlayers.jerseyNumber),
        OrderingTerm.asc(_database.players.displayName),
      ]);
    final rows = await query.get();
    return rows.map((row) => _toPlayer(row.readTable(_database.players))).toList(growable: false);
  }

  @override
  Future<List<TeamPlayer>> getActiveMemberships() async => _readMemberships(activeOnly: true);

  Future<List<TeamPlayer>> getAllMemberships() async => _readMemberships(activeOnly: false);

  Future<List<TeamPlayer>> _readMemberships({required bool activeOnly}) async {
    final query = _database.select(_database.teamPlayers);
    if (activeOnly) query.where((row) => row.isActive.equals(true));
    final rows = await query.get();
    return rows.map(_toMembership).toList(growable: false);
  }

  @override
  Future<TeamPlayer> addPlayerToTeam({required int teamId, required int playerId, int? jerseyNumber}) async {
    final existing = await (_database.select(_database.teamPlayers)
          ..where((row) => row.teamId.equals(teamId) & row.playerId.equals(playerId)))
        .getSingleOrNull();
    if (existing != null) {
      if (!existing.isActive) {
        await (_database.update(_database.teamPlayers)..where((row) => row.id.equals(existing.id)))
            .write(TeamPlayersCompanion(jerseyNumber: Value(jerseyNumber), isActive: const Value(true)));
        await _enqueue(existing.id);
        return TeamPlayer(id: existing.id, teamId: teamId, playerId: playerId, jerseyNumber: jerseyNumber);
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
    await _enqueue(id);
    return TeamPlayer(id: id, teamId: teamId, playerId: playerId, jerseyNumber: jerseyNumber);
  }

  @override
  Future<void> removePlayerFromTeam(int teamId, int playerId) async {
    final membership = await (_database.select(_database.teamPlayers)
          ..where((row) => row.teamId.equals(teamId) & row.playerId.equals(playerId)))
        .getSingleOrNull();
    if (membership == null) return;
    await (_database.update(_database.teamPlayers)..where((row) => row.id.equals(membership.id)))
        .write(const TeamPlayersCompanion(isActive: Value(false)));
    await _enqueue(membership.id);
  }

  @override
  Future<void> updateJerseyNumber(int teamId, int playerId, int? jerseyNumber) async {
    final membership = await (_database.select(_database.teamPlayers)
          ..where((row) => row.teamId.equals(teamId) & row.playerId.equals(playerId)))
        .getSingleOrNull();
    if (membership == null) return;
    await (_database.update(_database.teamPlayers)..where((row) => row.id.equals(membership.id)))
        .write(TeamPlayersCompanion(jerseyNumber: Value(jerseyNumber)));
    await _enqueue(membership.id);
  }

  Future<void> _enqueue(int id) async {
    final queue = _catalogSyncQueueRepository;
    final identity = _syncIdentityRepository;
    if (queue == null || identity == null) return;
    await queue.enqueue(
      syncId: await identity.ensureTeamPlayerSyncId(id),
      entityType: 'team_player',
      entityId: id,
    );
  }

  TeamPlayer _toMembership(TeamPlayer row) => TeamPlayer(
        id: row.id,
        teamId: row.teamId,
        playerId: row.playerId,
        jerseyNumber: row.jerseyNumber,
        isActive: row.isActive,
      );

  domain.Player _toPlayer(Player row) => domain.Player(
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
