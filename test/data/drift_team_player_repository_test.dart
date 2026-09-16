import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/data/database/app_database.dart';
import 'package:cricket_scorer/data/repositories/catalog_sync_queue_repository.dart';
import 'package:cricket_scorer/data/repositories/drift_sync_identity_repository.dart';
import 'package:cricket_scorer/data/repositories/drift_team_player_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late RecordingCatalogSyncQueueRepository queue;
  late DriftTeamPlayerRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    queue = RecordingCatalogSyncQueueRepository();
    repository = DriftTeamPlayerRepository(
      database,
      queue,
      DriftSyncIdentityRepository(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('removing a player soft-deletes membership and requeues it for sync', () async {
    final membership = await repository.addPlayerToTeam(
      teamId: 10,
      playerId: 20,
      jerseyNumber: 7,
    );

    queue.enqueuedSyncIds.clear();

    await repository.removePlayerFromTeam(10, 20);

    final memberships = await repository.getAllMemberships();
    expect(memberships, hasLength(1));
    expect(memberships.single.id, membership.id);
    expect(memberships.single.teamId, 10);
    expect(memberships.single.playerId, 20);
    expect(memberships.single.isActive, isFalse);

    expect(queue.enqueuedSyncIds, hasLength(1));
    expect(queue.enqueuedSyncIds.single, isNotEmpty);
  });

  test('inactive membership can be reactivated with the same local membership', () async {
    final membership = await repository.addPlayerToTeam(
      teamId: 10,
      playerId: 20,
    );

    await repository.removePlayerFromTeam(10, 20);
    final reactivated = await repository.addPlayerToTeam(
      teamId: 10,
      playerId: 20,
      jerseyNumber: 11,
    );

    expect(reactivated.id, membership.id);
    expect(reactivated.isActive, isTrue);
    expect(reactivated.jerseyNumber, 11);
  });
}

class RecordingCatalogSyncQueueRepository
    implements CatalogSyncQueueRepository {
  final enqueuedSyncIds = <String>[];

  @override
  Future<void> enqueue({
    required String syncId,
    required String entityType,
    required int entityId,
  }) async {
    enqueuedSyncIds.add(syncId);
  }

  @override
  Future<void> enqueueIfMissing({
    required String syncId,
    required String entityType,
    required int entityId,
  }) async {
    enqueuedSyncIds.add(syncId);
  }

  @override
  Future<CatalogSyncQueueEntry?> getBySyncId(String syncId) async => null;

  @override
  Future<List<CatalogSyncQueueEntry>> getPending({int limit = 100}) async =>
      const [];

  @override
  Future<void> markInProgress(String syncId) async {}

  @override
  Future<void> markSynced(String syncId) async {}

  @override
  Future<void> markFailed(
    String syncId, {
    required String error,
    required DateTime nextAttemptAt,
  }) async {}

  @override
  Future<void> resetInProgress() async {}
}
