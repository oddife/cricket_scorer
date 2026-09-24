import 'package:drift/drift.dart';

class Innings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get matchId => integer()();
  IntColumn get inningsNumber => integer()();
  IntColumn get battingTeamId => integer()();
  IntColumn get bowlingTeamId => integer()();
  IntColumn get openingStrikerId => integer()();
  IntColumn get openingNonStrikerId => integer()();
  IntColumn get openingBowlerId => integer()();
  IntColumn get oversPerInnings => integer()();
  IntColumn get ballsPerOver => integer()();
  BoolColumn get twoBowlerMode => boolean()();
  IntColumn get activeTwoBowlerOneId => integer().nullable()();
  IntColumn get activeTwoBowlerTwoId => integer().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {matchId, inningsNumber},
      ];
}
