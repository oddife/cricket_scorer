import 'package:drift/drift.dart';

import 'teams.dart';
import 'tournaments.dart';

class TournamentTeams extends Table {
  IntColumn get tournamentId => integer().references(Tournaments, #id)();

  IntColumn get teamId => integer().references(Teams, #id)();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tournamentId, teamId};
}
