import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/players.dart';
import 'tables/team_players.dart';
import 'tables/teams.dart';
import 'tables/tournaments.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Players, Teams, TeamPlayers, Tournaments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'cricket_scorer'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(players);
            await m.createTable(teams);
            await m.createTable(teamPlayers);
          }
        },
      );
}
