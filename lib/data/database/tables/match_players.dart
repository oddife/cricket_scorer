import 'package:drift/drift.dart';

class MatchPlayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get matchId => integer()();
  IntColumn get teamId => integer()();
  IntColumn get playerId => integer()();
  BoolColumn get isPlaying => boolean().withDefault(const Constant(false))();
  IntColumn get battingOrder => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {matchId, playerId},
      ];
}
