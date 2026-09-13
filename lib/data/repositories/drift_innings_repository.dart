import 'package:drift/drift.dart';

import '../../domain/innings/enums/innings_status.dart';
import '../../domain/innings/models/innings.dart';
import '../database/app_database.dart';
import '../database/tables/innings.dart' as table;
import 'innings_repository.dart';

class DriftInningsRepository implements InningsRepository {
  DriftInningsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Innings?> getById(int inningsId) async {
    final row = await (_db.select(_db.innings)
          ..where((t) => t.id.equals(inningsId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Innings?> getByMatchAndNumber(
    int matchId,
    int inningsNumber,
  ) async {
    final row = await (_db.select(_db.innings)
          ..where(
            (t) => t.matchId.equals(matchId) &
                t.inningsNumber.equals(inningsNumber),
          ))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<Innings>> getForMatch(int matchId) async {
    final rows = await (_db.select(_db.innings)
          ..where((t) => t.matchId.equals(matchId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.inningsNumber),
          ]))
        .get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Innings> create(Innings innings) async {
    _validate(innings);

    final id = await _db.into(_db.innings).insert(
          _toCompanion(innings, includeId: false),
        );
    return innings.copyWith(id: id);
  }

  @override
  Future<void> update(Innings innings) async {
    _validate(innings);

    final updated = await (_db.update(_db.innings)
          ..where((t) => t.id.equals(innings.id)))
        .write(_toCompanion(innings, includeId: false));
    if (updated != 1) {
      throw StateError('Innings ${innings.id} was not found.');
    }
  }

  Innings _fromRow(table.InningsData row) {
    return Innings(
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
      status: InningsStatus.fromDb(row.status),
      startedAt: row.startedAt,
      completedAt: row.completedAt,
    );
  }

  table.InningsCompanion _toCompanion(
    Innings innings, {
    required bool includeId,
  }) {
    return table.InningsCompanion(
      id: includeId ? Value(innings.id) : const Value.absent(),
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
      status: Value(innings.status.dbValue),
      startedAt: Value(innings.startedAt),
      completedAt: Value(innings.completedAt),
    );
  }

  void _validate(Innings innings) {
    if (innings.inningsNumber <= 0) {
      throw ArgumentError('Innings number must be greater than 0.');
    }
    if (innings.battingTeamId == innings.bowlingTeamId) {
      throw ArgumentError('Batting and bowling teams must be different.');
    }
    if (innings.openingStrikerId == innings.openingNonStrikerId) {
      throw ArgumentError('Opening striker and non-striker must be different.');
    }
    if (innings.oversPerInnings <= 0 || innings.ballsPerOver <= 0) {
      throw ArgumentError('Overs and balls per over must be greater than 0.');
    }
  }
}
