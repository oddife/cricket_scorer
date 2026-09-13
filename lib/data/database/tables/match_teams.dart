import 'package:drift/drift.dart';

class MatchTeams extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get matchId => integer()();
  IntColumn get teamId => integer()();
  IntColumn get slot => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {matchId, slot},
        {matchId, teamId},
      ];
}
