import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/catalog_sync_queue_repository.dart';
import '../../data/repositories/drift_ball_event_repository.dart';
import '../../data/repositories/drift_catalog_sync_queue_repository.dart';
import '../../data/repositories/drift_entity_identity_repository.dart';
import '../../data/repositories/drift_innings_repository.dart';
import '../../data/repositories/drift_match_repository.dart';
import '../../data/repositories/drift_player_repository.dart';
import '../../data/repositories/drift_sync_identity_repository.dart';
import '../../data/repositories/drift_sync_queue_repository.dart';
import '../../data/repositories/drift_team_player_repository.dart';
import '../../data/repositories/drift_team_repository.dart';
import '../../data/repositories/drift_tournament_points_repository.dart';
import '../../data/repositories/drift_tournament_repository.dart';
import '../../data/repositories/drift_tournament_team_repository.dart';
import '../../data/repositories/entity_identity_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/sync_identity_repository.dart';
import '../../data/repositories/sync_queue_repository.dart';
import '../../data/repositories/team_player_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/tournament_points_repository.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../data/repositories/tournament_team_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final entityIdentityRepositoryProvider = Provider<EntityIdentityRepository>(
  (ref) => DriftEntityIdentityRepository(ref.watch(appDatabaseProvider)),
);

/// Legacy synchronization identity provider. Existing sync transports remain
/// on sync_id until they are migrated to app_id/global_id.
final syncIdentityRepositoryProvider = Provider<SyncIdentityRepository>(
  (ref) => DriftSyncIdentityRepository(ref.watch(appDatabaseProvider)),
);

final catalogSyncQueueRepositoryProvider = Provider<CatalogSyncQueueRepository>(
  (ref) => DriftCatalogSyncQueueRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncIdentityRepositoryProvider),
  ),
);

final playerRepositoryProvider = Provider<PlayerRepository>((ref) =>
    DriftPlayerRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(catalogSyncQueueRepositoryProvider),
      ref.watch(syncIdentityRepositoryProvider),
      ref.watch(entityIdentityRepositoryProvider),
    ));

final teamRepositoryProvider = Provider<TeamRepository>((ref) =>
    DriftTeamRepository(ref.watch(appDatabaseProvider),
        ref.watch(catalogSyncQueueRepositoryProvider), ref.watch(syncIdentityRepositoryProvider)));
final teamPlayerRepositoryProvider = Provider<TeamPlayerRepository>((ref) =>
    DriftTeamPlayerRepository(ref.watch(appDatabaseProvider),
        ref.watch(catalogSyncQueueRepositoryProvider), ref.watch(syncIdentityRepositoryProvider)));
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) =>
    DriftTournamentRepository(ref.watch(appDatabaseProvider),
        ref.watch(catalogSyncQueueRepositoryProvider), ref.watch(syncIdentityRepositoryProvider)));
final tournamentPointsRepositoryProvider = Provider<TournamentPointsRepository>((ref) =>
    DriftTournamentPointsRepository(ref.watch(appDatabaseProvider),
        ref.watch(catalogSyncQueueRepositoryProvider), ref.watch(syncIdentityRepositoryProvider)));
final tournamentTeamRepositoryProvider = Provider<TournamentTeamRepository>((ref) =>
    DriftTournamentTeamRepository(ref.watch(appDatabaseProvider),
        ref.watch(catalogSyncQueueRepositoryProvider), ref.watch(syncIdentityRepositoryProvider)));
final matchRepositoryProvider = Provider<MatchRepository>((ref) => DriftMatchRepository(ref.watch(appDatabaseProvider)));
final inningsRepositoryProvider = Provider<InningsRepository>((ref) => DriftInningsRepository(ref.watch(appDatabaseProvider)));
final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) => DriftSyncQueueRepository(ref.watch(appDatabaseProvider)));
final ballEventRepositoryProvider = Provider<BallEventRepository>((ref) => DriftBallEventRepository(ref.watch(appDatabaseProvider), ref.watch(syncQueueRepositoryProvider)));
