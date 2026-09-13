import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/drift_player_repository.dart';
import '../../data/repositories/drift_team_player_repository.dart';
import '../../data/repositories/drift_team_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/team_player_repository.dart';
import '../../data/repositories/team_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return DriftPlayerRepository(ref.watch(appDatabaseProvider));
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return DriftTeamRepository(ref.watch(appDatabaseProvider));
});

final teamPlayerRepositoryProvider = Provider<TeamPlayerRepository>((ref) {
  return DriftTeamPlayerRepository(ref.watch(appDatabaseProvider));
});
