import 'package:drift/drift.dart';

import '../../domain/matches/enums/match_status.dart';
import '../../domain/matches/enums/match_team_slot.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/matches/models/match.dart' as domain;
import '../../domain/matches/models/match_player.dart' as match_domain;
import '../../domain/matches/models/match_team.dart' as match_team_domain;
import '../database/app_database.dart';
import 'match_repository.dart';

class DriftMatchRepository implements MatchRepository {
  DriftMatchRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Match>> getAll() async {
    final rows = await (_database.select(_database.matches)
          ..orderBy([(row) => OrderingTerm.desc(row.date)]))
        .get();
    return rows.map<domain.Match>(_toDomain).toList(growable: false);
  }

  @override
  Future<domain.Match?> getById(int matchId) async {
    final row = await (_database.select(_database.matches)
          ..where((row) => row.id.equals(matchId)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<domain.Match> create(domain.Match match) async {
    final now = DateTime.now();
    final id = await _database.into(_database.matches).insert(
          MatchesCompanion.insert(
            tournamentId: Value(match.tournamentId),
            name: match.name.trim(),
            date: match.date,
            venue: Value(match.venue?.trim()),
            inningsCount: match.inningsCount,
            oversPerInnings: match.oversPerInnings,
            ballsPerOver: match.ballsPerOver,
            playersPerTeam: match.playersPerTeam,
            twoBowlerMode: Value(match.twoBowlerMode),
            tossWinnerTeamId: Value(match.tossWinnerTeamId),
            tossDecision: Value(match.tossDecision?.dbValue),
            status: Value(match.status.dbValue),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return match.copyWith(id: id);
  }

  @override
  Future<void> update(domain.Match match) async {
    await (_database.update(_database.matches)
          ..where((row) => row.id.equals(match.id)))
        .write(
      MatchesCompanion(
        tournamentId: Value(match.tournamentId),
        name: Value(match.name.trim()),
        date: Value(match.date),
        venue: Value(match.venue?.trim()),
        inningsCount: Value(match.inningsCount),
        oversPerInnings: Value(match.oversPerInnings),
        ballsPerOver: Value(match.ballsPerOver),
        playersPerTeam: Value(match.playersPerTeam),
        twoBowlerMode: Value(match.twoBowlerMode),
        tossWinnerTeamId: Value(match.tossWinnerTeamId),
        tossDecision: Value(match.tossDecision?.dbValue),
        status: Value(match.status.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(int matchId) async {
    await (_database.delete(_database.matchPlayers)
          ..where((row) => row.matchId.equals(matchId)))
        .go();
    await (_database.delete(_database.matchTeams)
          ..where((row) => row.matchId.equals(matchId)))
        .go();
    await (_database.delete(_database.matches)
          ..where((row) => row.id.equals(matchId)))
        .go();
  }

  @override
  Future<void> setTeam({
    required int matchId,
    required int teamId,
    required MatchTeamSlot slot,
  }) async {
    final existing = await (_database.select(_database.matchTeams)
          ..where((row) =>
              row.matchId.equals(matchId) & row.slot.equals(slot.dbValue)))
        .getSingleOrNull();

    if (existing != null) {
      await (_database.update(_database.matchTeams)
            ..where((row) => row.id.equals(existing.id)))
          .write(MatchTeamsCompanion(teamId: Value(teamId)));
      return;
    }

    await _database.into(_database.matchTeams).insert(
          MatchTeamsCompanion.insert(
            matchId: matchId,
            teamId: teamId,
            slot: slot.dbValue,
          ),
        );
  }

  @override
  Future<void> removeTeam(int matchId, MatchTeamSlot slot) async {
    await (_database.delete(_database.matchTeams)
          ..where((row) =>
              row.matchId.equals(matchId) & row.slot.equals(slot.dbValue)))
        .go();
  }

  @override
  Future<List<match_team_domain.MatchTeam>> getTeams(int matchId) async {
    final rows = await (_database.select(_database.matchTeams)
          ..where((row) => row.matchId.equals(matchId))
          ..orderBy([(row) => OrderingTerm.asc(row.slot)]))
        .get();
    return rows
        .map((row) => match_team_domain.MatchTeam(
              id: row.id,
              matchId: row.matchId,
              teamId: row.teamId,
              slot: matchTeamSlotFromDbValue(row.slot),
            ))
        .toList(growable: false);
  }

  @override
  Future<void> addPlayer({
    required int matchId,
    required int teamId,
    required int playerId,
  }) async {
    final existing = await (_database.select(_database.matchPlayers)
          ..where((row) =>
              row.matchId.equals(matchId) & row.playerId.equals(playerId)))
        .getSingleOrNull();

    if (existing != null) {
      throw StateError('Player is already part of this match.');
    }

    await _database.into(_database.matchPlayers).insert(
          MatchPlayersCompanion.insert(
            matchId: matchId,
            teamId: teamId,
            playerId: playerId,
          ),
        );
  }

  @override
  Future<void> removePlayer(int matchId, int playerId) async {
    await (_database.delete(_database.matchPlayers)
          ..where((row) =>
              row.matchId.equals(matchId) & row.playerId.equals(playerId)))
        .go();
  }

  @override
  Future<void> setPlayingXi({
    required int matchId,
    required int teamId,
    required List<int> playerIds,
  }) async {
    final rows = await (_database.select(_database.matchPlayers)
          ..where((row) =>
              row.matchId.equals(matchId) & row.teamId.equals(teamId)))
        .get();

    final selected = playerIds.toSet();
    for (final row in rows) {
      final index = playerIds.indexOf(row.playerId);
      await (_database.update(_database.matchPlayers)
            ..where((item) => item.id.equals(row.id)))
          .write(
        MatchPlayersCompanion(
          isPlaying: Value(selected.contains(row.playerId)),
          battingOrder: Value(index >= 0 ? index + 1 : null),
        ),
      );
    }
  }

  @override
  Future<List<match_domain.MatchPlayer>> getPlayers(int matchId) async {
    final rows = await (_database.select(_database.matchPlayers)
          ..where((row) => row.matchId.equals(matchId))
          ..orderBy([
            OrderingTerm.asc(row.teamId),
            OrderingTerm.asc(row.battingOrder),
            OrderingTerm.asc(row.id),
          ]))
        .get();
    return rows
        .map((row) => match_domain.MatchPlayer(
              id: row.id,
              matchId: row.matchId,
              teamId: row.teamId,
              playerId: row.playerId,
              isPlaying: row.isPlaying,
              battingOrder: row.battingOrder,
            ))
        .toList(growable: false);
  }

  @override
  Future<void> setToss({
    required int matchId,
    required int tossWinnerTeamId,
    required TossDecision decision,
  }) async {
    await (_database.update(_database.matches)
          ..where((row) => row.id.equals(matchId)))
        .write(
      MatchesCompanion(
        tossWinnerTeamId: Value(tossWinnerTeamId),
        tossDecision: Value(decision.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  domain.Match _toDomain(Match row) {
    return domain.Match(
      id: row.id,
      tournamentId: row.tournamentId,
      name: row.name,
      date: row.date,
      venue: row.venue,
      inningsCount: row.inningsCount,
      oversPerInnings: row.oversPerInnings,
      ballsPerOver: row.ballsPerOver,
      playersPerTeam: row.playersPerTeam,
      twoBowlerMode: row.twoBowlerMode,
      tossWinnerTeamId: row.tossWinnerTeamId,
      tossDecision: row.tossDecision == null
          ? null
          : tossDecisionFromDbValue(row.tossDecision!),
      status: matchStatusFromDbValue(row.status),
    );
  }
}
