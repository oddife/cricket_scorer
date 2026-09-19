import 'package:drift/drift.dart';

import '../../domain/players/enums/batting_style.dart';
import '../../domain/players/enums/bowling_style.dart';
import '../../domain/players/models/player.dart' as domain;
import '../../domain/teams/models/team_player.dart' as domain_team;
import '../database/app_database.dart';
import 'catalog_sync_queue_repository.dart';
import 'entity_identity_repository.dart';
import 'sync_identity_repository.dart';
import 'team_player_repository.dart';

class DriftTeamPlayerRepository implements TeamPlayerRepository {
  DriftTeamPlayerRepository(
    this._database, [
    this._catalogSyncQueueRepository,
    this._syncIdentityRepository,
    this._entityIdentityRepository,
  ]);

  final AppDatabase _database;
  final CatalogSyncQueueRepository? _catalogSyncQueueRepository;
  final SyncIdentityRepository? _syncIdentityRepository;
  final EntityIdentityRepository? _entityIdentityRepository;

  @override
  Future<List<domain.Player>> getPlayersForTeam(int teamId) async {
    final query = _database.select(_database.players).join([
      innerJoin(
        _database.teamPlayers,
        _database.teamPlayers.playerId.equalsExp(_database.players.id),
      ),
    ])
      ..where(_database.teamPlayers.teamId.equals(teamId) &
          _database.teamPlayers.isActive.equals(true) &
          _database.players.isActive.equals(true))
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
  Future<List<domain_team.TeamPlayer>> getActiveMemberships() async =>
      _readMemberships(activeOnly: true);

  @override
  Future<List<domain_team.TeamPlayer>> getAllMemberships() async =>
      _readMemberships(activeOnly: false);

  Future<List<domain_team.TeamPlayer>> _readMemberships({
    required bool activeOnly,
  }) async {
    final query = _database.select(_database.teamPlayers);
    if (activeOnly) query.where((row) => row.isActive.equals(true));
    final rows = await query.get();
    return rows
        .map<domain_team.TeamPlayer>(_toMembership)
        .toList(growable: false);
  }

  @override
  Future<domain_team.TeamPlayer> addPlayerToTeam({
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
        await _ensureAppIdentity(existing.id);
        await _enqueue(existing.id);
        return domain_team.TeamPlayer(
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
    await _ensureAppIdentity(id);
    await _enqueue(id);
    return domain_team.TeamPlayer(
      id: id,
      teamId: teamId,
      playerId: playerId,
      jerseyNumber: jerseyNumber,
    );
  }

  @override
  Future<void> removePlayerFromTeam(int teamId, int playerId) async {
    final membership = await (_database.select(_database.teamPlayers)
          ..where(
            (row) => row.teamId.equals(teamId) & row.playerId.equals(playerId),
          ))
        .getSingleOrNull();
    if (membership == null) return;
    await _ensureAppIdentity(membership.id);
    await (_database.update(_database.teamPlayers)
          ..where((row) => row.id.equals(membership.id)))
        .write(const TeamPlayersCompanion(isActive: Value(false)));
    await _enqueue(membership.id);
  }

  @override
  Future<void> updateJerseyNumber(
    int teamId,
    int playerId,
    int? jerseyNumber,
  ) async {
    final membership = await (_database.select(_database.teamPlayers)
          ..where(
            (row) => row.teamId.equals(teamId) & row.playerId.equals(playerId),
          ))
        .getSingleOrNull();
    if (membership == null) return;
    await _ensureAppIdentity(membership.id);
    await (_database.update(_database.teamPlayers)
          ..where((row) => row.id.equals(membership.id)))
        .write(TeamPlayersCompanion(jerseyNumber: Value(jerseyNumber)));
    await _enqueue(membership.id);
  }

  Future<void> _ensureAppIdentity(int id) async {
    await _entityIdentityRepository?.ensure('team_player', id);
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

  domain_team.TeamPlayer _toMembership(TeamPlayer row) =>
      domain_team.TeamPlayer(
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
