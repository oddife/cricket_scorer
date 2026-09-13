import 'package:drift/drift.dart';

class BallEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get inningsId => integer()();
  IntColumn get sequenceNumber => integer()();
  IntColumn get overNumber => integer()();
  IntColumn get legalBallNumber => integer()();
  IntColumn get bowlerId => integer()();
  IntColumn get strikerId => integer()();
  IntColumn get nonStrikerId => integer()();
  IntColumn get deliveryType => integer()();
  BoolColumn get isLegalBall => boolean()();
  IntColumn get batterRuns => integer()();
  IntColumn get byeRuns => integer()();
  IntColumn get legByeRuns => integer()();
  IntColumn get wideRuns => integer()();
  IntColumn get noBallRuns => integer()();
  IntColumn get totalRuns => integer()();
  IntColumn get wicketType => integer().nullable()();
  IntColumn get dismissedPlayerId => integer().nullable()();
  IntColumn get fielderId => integer().nullable()();
  IntColumn get runOutEnd => integer().nullable()();
  BoolColumn get creditedToBowler => boolean().nullable()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {inningsId, sequenceNumber},
      ];
}
