import 'package:drift/drift.dart';

class Matches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tournamentId => integer().nullable()();
  TextColumn get name => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get venue => text().nullable()();
  IntColumn get inningsCount => integer()();
  IntColumn get oversPerInnings => integer()();
  IntColumn get ballsPerOver => integer()();
  IntColumn get playersPerTeam => integer()();
  BoolColumn get twoBowlerMode => boolean().withDefault(const Constant(false))();
  IntColumn get tossWinnerTeamId => integer().nullable()();
  IntColumn get tossDecision => integer().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
