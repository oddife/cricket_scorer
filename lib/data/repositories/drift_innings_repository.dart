import 'package:drift/drift.dart';

import '../../domain/innings/enums/innings_status.dart';
import '../../domain/innings/models/innings.dart';
import '../database/app_database.dart' as db;
import 'entity_identity_repository.dart';
import 'innings_repository.dart';

class DriftInningsRepository implements InningsRepository {
  DriftInningsRepository(this._db, [this._entityIdentityRepository]);

  final db.AppDatabase _db;
  final EntityIdentityRepository? _entityIdentityRepository;

  @override
  Future<Innings?> getById(int inningsId) async {
    final row = await (_db.select(_db.innings)
          ..where((t) => t.id.equals(inningsId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Innings?> getByMatchAndNumber(int matchId, int inningsNumber) async {
    final row = await (_db.select(_db.innings)
          ..where((t) => t.matchId.equals(matchId) & t.inningsNumber.equals(inningsNumber)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<Innings>> getForMatch(int matchId) async {
    final rows = await (_db.select(_db.innings)
          ..where((t) => t.matchId.equals(matchId))
          ..orderBy([(t) => OrderingTerm(expression: t.inningsNumber)]))
        .get();
    return rows.map<Innings>(_fromRow).toList(growable: false);
  }

  @override
  Future<Innings> create(Innings innings) async {
    _validate(innings);
    await _ensureRelatedIdentities(innings);
    final id = await _db.into(_db.innings).insert(_toCompanion(innings));
    await _entityIdentityRepository?.ensure('innings', id);
    return innings.copyWith(id: id);
  }

  @override
  Future<void> update(Innings innings) async {
    _validate(innings);
    await _ensureRelatedIdentities(innings);
    await _entityIdentityRepository?.ensure('innings', innings.id);
    final updated = await (_db.update(_db.innings)..where((t) => t.id.equals(innings.id)))
        .write(_toCompanion(innings));
    if (updated != 1) throw StateError('Innings ${innings.id} was not found.');
  }

  Future<void> _ensureRelatedIdentities(Innings innings) async {
    final repo = _entityIdentityRepository;
    if (repo == null) return;
    await repo.ensure('match', innings.matchId);
    await repo.ensure('team', innings.battingTeamId);
    await repo.ensure('team', innings.bowlingTeamId);
    await repo.ensure('player', innings.openingStrikerId);
    await repo.ensure('player', innings.openingNonStrikerId);
    await repo.ensure('player', innings.openingBowlerId);
  }

  Innings _fromRow(db.Inning row) => Innings(
        id: row.id,
        matchId: row.matchId,
        inningsNumber: row.inningsNumber,
        battingTeamId: row.battingTeamId,
        bowlingTeamId: row.bowlingTeamId,
        openingStrikerId: row.openingStrikerId,
        openingNonStrikerId: row.openingNonStrikerId,
        openingBowlerId: row.openingBowlerId,
        oversPerInnings: row.oversPerInnings,
        ballsPerOver: row.ballsPerOver,
        twoBowlerMode: row.twoBowlerMode,
        activeTwoBowlerOneId: row.activeTwoBowlerOneId,
        activeTwoBowlerTwoId: row.activeTwoBowlerTwoId,
        status: InningsStatus.fromDb(row.status),
        startedAt: row.startedAt,
        completedAt: row.completedAt,
      );

  db.InningsCompanion _toCompanion(Innings innings) => db.InningsCompanion(
        id: innings.id == 0 ? const Value.absent() : Value(innings.id),
        matchId: Value(innings.matchId),
        inningsNumber: Value(innings.inningsNumber),
        battingTeamId: Value(innings.battingTeamId),
        bowlingTeamId: Value(innings.bowlingTeamId),
        openingStrikerId: Value(innings.openingStrikerId),
        openingNonStrikerId: Value(innings.openingNonStrikerId),
        openingBowlerId: Value(innings.openingBowlerId),
        oversPerInnings: Value(innings.oversPerInnings),
        ballsPerOver: Value(innings.ballsPerOver),
        twoBowlerMode: Value(innings.twoBowlerMode),
        activeTwoBowlerOneId: Value(innings.activeTwoBowlerOneId),
        activeTwoBowlerTwoId: Value(innings.activeTwoBowlerTwoId),
        status: Value(innings.status.dbValue),
        startedAt: Value(innings.startedAt),
        completedAt: Value(innings.completedAt),
      );

  void _validate(Innings innings) {
    if (innings.inningsNumber <= 0) throw ArgumentError('Innings number must be greater than 0.');
    if (innings.battingTeamId == innings.bowlingTeamId) throw ArgumentError('Batting and bowling teams must be different.');
    if (innings.openingStrikerId == innings.openingNonStrikerId) throw ArgumentError('Opening striker and non-striker must be different.');
    if (innings.oversPerInnings <= 0 || innings.ballsPerOver <= 0) throw ArgumentError('Overs and balls per over must be greater than 0.');
  }
}
