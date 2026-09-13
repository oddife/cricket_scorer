import 'package:drift/drift.dart';

class TeamPlayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get teamId => integer()();
  IntColumn get playerId => integer()();
  IntColumn get jerseyNumber => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {teamId, playerId},
      ];
}
