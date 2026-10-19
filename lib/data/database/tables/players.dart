import 'package:drift/drift.dart';

class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get photoPath => text().nullable()();
  IntColumn get jerseyNumber => integer().nullable()();
  IntColumn get battingStyle => integer().withDefault(const Constant(0))();
  IntColumn get bowlingStyle => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
