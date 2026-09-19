import 'package:drift/drift.dart';

import '../../domain/matches/enums/match_status.dart';
import '../../domain/matches/enums/match_team_slot.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/matches/models/match.dart' as domain;
import '../../domain/matches/models/match_player.dart' as match_domain;
import '../../domain/matches/models/match_team.dart' as match_team_domain;
import '../database/app_database.dart' as db;
import 'entity_identity_repository.dart';
import 'match_repository.dart';

class DriftMatchRepository implements MatchRepository {
  DriftMatchRepository(this._database, [this._entityIdentityRepository]);

  final db.AppDatabase _database;
  final EntityIdentityRepository? _entityIdentityRepository;

  @override
  Future<List<domain.Match>> getAll() async {
    final rows = await (_database.select(_database.matches)..orderBy([(row) => OrderingTerm.desc(row.date)])).get();
    return rows.map<domain.Match>((row) => _toDomain(row)).toList(growable: false);
  }

  @override
  Future<domain.Match?> getById(int matchId) async {
    final row = await (_database.select(_database.matches)..where((row) => row.id.equals(matchId))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<domain.Match> create(domain.Match match) async {
    _validateMatch(match);
    if (match.tournamentId != null) await _ensureIdentity('tournament', match.tournamentId!);
    final now = DateTime.now();
    final id = await _database.into(_database.matches).insert(db.MatchesCompanion.insert(
      tournamentId: Value(match.tournamentId), name: match.name.trim(), date: match.date,
      venue: Value(match.venue?.trim()), inningsCount: match.inningsCount,
      oversPerInnings: match.oversPerInnings, ballsPerOver: match.ballsPerOver,
      playersPerTeam: match.playersPerTeam, twoBowlerMode: Value(match.twoBowlerMode),
      tossWinnerTeamId: Value(match.tossWinnerTeamId), tossDecision: Value(match.tossDecision?.dbValue),
      status: Value(match.status.dbValue), createdAt: now, updatedAt: now,
    ));
    await _ensureIdentity('match', id);
    return match.copyWith(id: id);
  }

  @override
  Future<void> update(domain.Match match) async {
    _validateMatch(match);
    await _ensureIdentity('match', match.id);
    if (match.tournamentId != null) await _ensureIdentity('tournament', match.tournamentId!);
    await (_database.update(_database.matches)..where((row) => row.id.equals(match.id))).write(db.MatchesCompanion(
      tournamentId: Value(match.tournamentId), name: Value(match.name.trim()), date: Value(match.date),
      venue: Value(match.venue?.trim()), inningsCount: Value(match.inningsCount),
      oversPerInnings: Value(match.oversPerInnings), ballsPerOver: Value(match.ballsPerOver),
      playersPerTeam: Value(match.playersPerTeam), twoBowlerMode: Value(match.twoBowlerMode),
      tossWinnerTeamId: Value(match.tossWinnerTeamId), tossDecision: Value(match.tossDecision?.dbValue),
      status: Value(match.status.dbValue), updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> delete(int matchId) async {
    await (_database.delete(_database.innings)..where((row) => row.matchId.equals(matchId))).go();
    await (_database.delete(_database.matchPlayers)..where((row) => row.matchId.equals(matchId))).go();
    await (_database.delete(_database.matchTeams)..where((row) => row.matchId.equals(matchId))).go();
    await (_database.delete(_database.matches)..where((row) => row.id.equals(matchId))).go();
  }

  @override
  Future<void> setTeam({required int matchId, required int teamId, required MatchTeamSlot slot}) async {
    await _ensureIdentity('match', matchId);
    await _ensureIdentity('team', teamId);
    final existing = await (_database.select(_database.matchTeams)..where((row) => row.matchId.equals(matchId) & row.slot.equals(slot.dbValue))).getSingleOrNull();
    if (existing != null) {
      await (_database.update(_database.matchTeams)..where((row) => row.id.equals(existing.id))).write(db.MatchTeamsCompanion(teamId: Value(teamId)));
      return;
    }
    await _database.into(_database.matchTeams).insert(db.MatchTeamsCompanion.insert(matchId: matchId, teamId: teamId, slot: slot.dbValue));
  }

  @override
  Future<void> removeTeam(int matchId, MatchTeamSlot slot) async {
    await _ensureIdentity('match', matchId);
    await (_database.delete(_database.matchTeams)..where((row) => row.matchId.equals(matchId) & row.slot.equals(slot.dbValue))).go();
  }

  @override
  Future<List<match_team_domain.MatchTeam>> getTeams(int matchId) async {
    final rows = await (_database.select(_database.matchTeams)..where((row) => row.matchId.equals(matchId))..orderBy([(row) => OrderingTerm.asc(row.slot)])).get();
    return rows.map((row) => match_team_domain.MatchTeam(id: row.id, matchId: row.matchId, teamId: row.teamId, slot: matchTeamSlotFromDbValue(row.slot))).toList(growable: false);
  }

  @override
  Future<void> addPlayer({required int matchId, required int teamId, required int playerId}) async {
    await _ensureIdentity('match', matchId);
    await _ensureIdentity('team', teamId);
    await _ensureIdentity('player', playerId);
    final existing = await (_database.select(_database.matchPlayers)..where((row) => row.matchId.equals(matchId) & row.playerId.equals(playerId))).getSingleOrNull();
    if (existing != null) throw StateError('Player is already part of this match.');
    await _database.into(_database.matchPlayers).insert(db.MatchPlayersCompanion.insert(matchId: matchId, teamId: teamId, playerId: playerId));
  }

  @override
  Future<void> removePlayer(int matchId, int playerId) async {
    await _ensureIdentity('match', matchId);
    await (_database.delete(_database.matchPlayers)..where((row) => row.matchId.equals(matchId) & row.playerId.equals(playerId))).go();
  }

  @override
  Future<void> setAvailablePlayers({required int matchId, required int teamId, required List<int> playerIds}) async {
    final uniqueIds = playerIds.toSet();
    if (uniqueIds.length != playerIds.length) throw ArgumentError('Match players cannot contain duplicates.');
    await _ensureIdentity('match', matchId);
    await _ensureIdentity('team', teamId);
    for (final playerId in uniqueIds) { await _ensureIdentity('player', playerId); }
    final rows = await (_database.select(_database.matchPlayers)..where((row) => row.matchId.equals(matchId) & row.teamId.equals(teamId))).get();
    final available = rows.map((row) => row.playerId).toSet();
    if (!available.containsAll(uniqueIds)) throw ArgumentError('Every selected player must belong to this match team.');
    for (final row in rows) {
      await (_database.update(_database.matchPlayers)..where((item) => item.id.equals(row.id))).write(db.MatchPlayersCompanion(isPlaying: Value(uniqueIds.contains(row.playerId)), battingOrder: Value<int?>(null)));
    }
  }

  @override
  Future<void> setPlayingXi({required int matchId, required int teamId, required List<int> playerIds}) async {
    final uniqueIds = playerIds.toSet();
    if (uniqueIds.length != playerIds.length) throw ArgumentError('Playing XI cannot contain duplicate players.');
    await _ensureIdentity('match', matchId);
    await _ensureIdentity('team', teamId);
    for (final playerId in uniqueIds) { await _ensureIdentity('player', playerId); }
    final match = await getById(matchId);
    if (match == null) throw StateError('Match not found.');
    if (playerIds.length > match.playersPerTeam) throw ArgumentError('Playing XI exceeds the configured team size.');
    final rows = await (_database.select(_database.matchPlayers)..where((row) => row.matchId.equals(matchId) & row.teamId.equals(teamId))).get();
    final available = rows.map((row) => row.playerId).toSet();
    if (!available.containsAll(uniqueIds)) throw ArgumentError('Every Playing XI player must belong to this match team.');
    for (final row in rows) {
      final index = playerIds.indexOf(row.playerId);
      await (_database.update(_database.matchPlayers)..where((item) => item.id.equals(row.id))).write(db.MatchPlayersCompanion(isPlaying: Value(index >= 0), battingOrder: Value(index >= 0 ? index + 1 : null)));
    }
  }

  @override
  Future<List<match_domain.MatchPlayer>> getPlayers(int matchId) async {
    final rows = await (_database.select(_database.matchPlayers)..where((row) => row.matchId.equals(matchId))..orderBy([(row) => OrderingTerm.asc(row.teamId), (row) => OrderingTerm.asc(row.battingOrder), (row) => OrderingTerm.asc(row.id)])).get();
    return rows.map((row) => match_domain.MatchPlayer(id: row.id, matchId: row.matchId, teamId: row.teamId, playerId: row.playerId, isPlaying: row.isPlaying, battingOrder: row.battingOrder)).toList(growable: false);
  }

  @override
  Future<void> setToss({required int matchId, required int tossWinnerTeamId, required TossDecision decision}) async {
    await _ensureIdentity('match', matchId);
    await _ensureIdentity('team', tossWinnerTeamId);
    final teams = await getTeams(matchId);
    if (!teams.any((team) => team.teamId == tossWinnerTeamId)) throw ArgumentError('Toss winner must be one of the match teams.');
    await (_database.update(_database.matches)..where((row) => row.id.equals(matchId))).write(db.MatchesCompanion(tossWinnerTeamId: Value(tossWinnerTeamId), tossDecision: Value(decision.dbValue), updatedAt: Value(DateTime.now())));
  }

  Future<void> _ensureIdentity(String type, int localId) async => _entityIdentityRepository?.ensure(type, localId);

  void _validateMatch(domain.Match match) {
    if (match.name.trim().isEmpty) throw ArgumentError('Match name is required.');
    if (match.inningsCount != 2 && match.inningsCount != 4) throw ArgumentError('Innings count must be 2 or 4.');
    if (match.oversPerInnings <= 0) throw ArgumentError('Overs must be positive.');
    if (match.ballsPerOver <= 0) throw ArgumentError('Balls per over must be positive.');
    if (match.playersPerTeam <= 0) throw ArgumentError('Players per team must be positive.');
  }

  domain.Match _toDomain(db.Matche row) => domain.Match(id: row.id, tournamentId: row.tournamentId, name: row.name, date: row.date, venue: row.venue, inningsCount: row.inningsCount, oversPerInnings: row.oversPerInnings, ballsPerOver: row.ballsPerOver, playersPerTeam: row.playersPerTeam, twoBowlerMode: row.twoBowlerMode, tossWinnerTeamId: row.tossWinnerTeamId, tossDecision: row.tossDecision == null ? null : tossDecisionFromDbValue(row.tossDecision!), status: matchStatusFromDbValue(row.status));
}
