import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/tournaments.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tournaments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'cricket_scorer'));

  @override
  int get schemaVersion => 1;
}
