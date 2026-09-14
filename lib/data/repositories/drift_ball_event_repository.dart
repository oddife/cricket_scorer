import 'package:drift/drift.dart';

import '../../domain/scoring/enums/delivery_type.dart';
import '../../domain/scoring/enums/run_out_end.dart';
import '../../domain/scoring/enums/wicket_type.dart';
import '../../domain/scoring/models/ball_event.dart';
import '../../domain/scoring/models/wicket.dart';
import '../database/app_database.dart' as db;
import 'ball_event_repository.dart';

class DriftBallEventRepository implements BallEventRepository {
  DriftBallEventRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<BallEvent> create(BallEvent event) async {
    _validate(event);
    final id = await _db.into(_db.ballEvents).insert(_toCompanion(event));
    if (event.wicket != null) {
      await _saveWicketContext(id, event.wicket!);
    }
    return _copyWithId(event, id);
  }

  @override
  Future<List<BallEvent>> getForInnings(int inningsId) async {
    final rows = await (_db.select(_db.ballEvents)
          ..where((t) => t.inningsId.equals(inningsId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sequenceNumber),
          ]))
        .get();
    return Future.wait(rows.map(_fromRow));
  }

  @override
  Future<BallEvent?> getBySequence(int inningsId, int sequenceNumber) async {
    final row = await (_db.select(_db.ballEvents)
          ..where((t) =>
              t.inningsId.equals(inningsId) &
              t.sequenceNumber.equals(sequenceNumber)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<void> deleteById(int id) async {
    await _db.customStatement(
      'DELETE FROM wicket_event_contexts WHERE ball_event_id = ?',
      variables: [Variable.withInt(id)],
    );
    final deleted = await (_db.delete(_db.ballEvents)
          ..where((t) => t.id.equals(id)))
        .go();
    if (deleted != 1) {
      throw StateError('Ball event $id was not found.');
    }
  }

  Future<BallEvent> _fromRow(db.BallEvent row) async {
    final wicketType = row.wicketType;
    final dismissedPlayerId = row.dismissedPlayerId;
    final creditedToBowler = row.creditedToBowler;

    Wicket? wicket;
    if (wicketType != null && dismissedPlayerId != null && creditedToBowler != null) {
      final context = await _loadWicketContext(row.id);
      wicket = Wicket(
        type: WicketType.values[wicketType],
        dismissedPlayerId: dismissedPlayerId,
        fielderId: row.fielderId,
        runOutEnd: row.runOutEnd == null ? null : RunOutEnd.values[row.runOutEnd!],
        completedRuns: context?.completedRuns ?? 0,
        crossedBeforeWicket: context?.crossedBeforeWicket ?? false,
        replacementBatterId: context?.replacementBatterId,
        creditedToBowler: creditedToBowler,
      );
    }

    return BallEvent(
      id: row.id,
      inningsId: row.inningsId,
      sequenceNumber: row.sequenceNumber,
      overNumber: row.overNumber,
      legalBallNumber: row.legalBallNumber,
      bowlerId: row.bowlerId,
      strikerId: row.strikerId,
      nonStrikerId: row.nonStrikerId,
      deliveryType: DeliveryType.values[row.deliveryType],
      isLegalBall: row.isLegalBall,
      batterRuns: row.batterRuns,
      byeRuns: row.byeRuns,
      legByeRuns: row.legByeRuns,
      wideRuns: row.wideRuns,
      noBallRuns: row.noBallRuns,
      totalRuns: row.totalRuns,
      wicket: wicket,
      timestamp: row.timestamp,
    );
  }

  db.BallEventsCompanion _toCompanion(BallEvent event) {
    return db.BallEventsCompanion(
      id: event.id == 0 ? const Value.absent() : Value(event.id),
      inningsId: Value(event.inningsId),
      sequenceNumber: Value(event.sequenceNumber),
      overNumber: Value(event.overNumber),
      legalBallNumber: Value(event.legalBallNumber),
      bowlerId: Value(event.bowlerId),
      strikerId: Value(event.strikerId),
      nonStrikerId: Value(event.nonStrikerId),
      deliveryType: Value(event.deliveryType.index),
      isLegalBall: Value(event.isLegalBall),
      batterRuns: Value(event.batterRuns),
      byeRuns: Value(event.byeRuns),
      legByeRuns: Value(event.legByeRuns),
      wideRuns: Value(event.wideRuns),
      noBallRuns: Value(event.noBallRuns),
      totalRuns: Value(event.totalRuns),
      wicketType: Value(event.wicket?.type.index),
      dismissedPlayerId: Value(event.wicket?.dismissedPlayerId),
      fielderId: Value(event.wicket?.fielderId),
      runOutEnd: Value(event.wicket?.runOutEnd?.index),
      creditedToBowler: Value(event.wicket?.creditedToBowler),
      timestamp: Value(event.timestamp),
    );
  }

  Future<void> _saveWicketContext(int ballEventId, Wicket wicket) async {
    await _db.customStatement(
      '''
      INSERT INTO wicket_event_contexts
        (ball_event_id, completed_runs, crossed_before_wicket, replacement_batter_id)
      VALUES (?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(ballEventId),
        Variable.withInt(wicket.completedRuns),
        Variable.withInt(wicket.crossedBeforeWicket ? 1 : 0),
        if (wicket.replacementBatterId == null)
          const Variable(null)
        else
          Variable.withInt(wicket.replacementBatterId!),
      ],
    );
  }

  Future<_WicketContext?> _loadWicketContext(int ballEventId) async {
    final rows = await _db.customSelect(
      '''
      SELECT completed_runs, crossed_before_wicket, replacement_batter_id
      FROM wicket_event_contexts
      WHERE ball_event_id = ?
      ''',
      variables: [Variable.withInt(ballEventId)],
    ).get();
    if (rows.isEmpty) return null;
    final row = rows.single.data;
    return _WicketContext(
      completedRuns: row['completed_runs'] as int,
      crossedBeforeWicket: (row['crossed_before_wicket'] as int) != 0,
      replacementBatterId: row['replacement_batter_id'] as int?,
    );
  }

  BallEvent _copyWithId(BallEvent event, int id) {
    return BallEvent(
      id: id,
      inningsId: event.inningsId,
      sequenceNumber: event.sequenceNumber,
      overNumber: event.overNumber,
      legalBallNumber: event.legalBallNumber,
      bowlerId: event.bowlerId,
      strikerId: event.strikerId,
      nonStrikerId: event.nonStrikerId,
      deliveryType: event.deliveryType,
      isLegalBall: event.isLegalBall,
      batterRuns: event.batterRuns,
      byeRuns: event.byeRuns,
      legByeRuns: event.legByeRuns,
      wideRuns: event.wideRuns,
      noBallRuns: event.noBallRuns,
      totalRuns: event.totalRuns,
      wicket: event.wicket,
      timestamp: event.timestamp,
    );
  }

  void _validate(BallEvent event) {
    if (event.inningsId <= 0) throw ArgumentError.value(event.inningsId, 'inningsId');
    if (event.sequenceNumber <= 0) {
      throw ArgumentError.value(event.sequenceNumber, 'sequenceNumber');
    }
    if (event.overNumber <= 0) throw ArgumentError.value(event.overNumber, 'overNumber');
    if (event.legalBallNumber < 0) {
      throw ArgumentError.value(event.legalBallNumber, 'legalBallNumber');
    }
  }
}

class _WicketContext {
  const _WicketContext({
    required this.completedRuns,
    required this.crossedBeforeWicket,
    required this.replacementBatterId,
  });

  final int completedRuns;
  final bool crossedBeforeWicket;
  final int? replacementBatterId;
}
