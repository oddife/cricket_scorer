import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/data/database/app_database.dart';
import 'package:cricket_scorer/data/repositories/drift_catalog_sync_queue_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DriftCatalogSyncQueueRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = DriftCatalogSyncQueueRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('enqueue creates a pending entry', () async {
    await repository.enqueue(
      syncId: 'team-sync-1',
      entityType: 'team',
      entityId: 1,
    );

    final pending = await repository.getPending();

    expect(pending, hasLength(1));
    expect(pending.single.syncId, 'team-sync-1');
    expect(pending.single.entityType, 'team');
    expect(pending.single.entityId, 1);
    expect(pending.single.status, 'pending');
    expect(pending.single.attempts, 0);
  });

  test('markInProgress increments attempts and markSynced clears retry state', () async {
    await repository.enqueue(
      syncId: 'player-sync-1',
      entityType: 'player',
      entityId: 1,
    );

    await repository.markInProgress('player-sync-1');
    await repository.markFailed(
      'player-sync-1',
      error: 'temporary failure',
      nextAttemptAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
    );

    var pending = await repository.getPending();
    expect(pending.single.attempts, 1);
    expect(pending.single.status, 'failed');
    expect(pending.single.lastError, 'temporary failure');

    await repository.markInProgress('player-sync-1');
    await repository.markSynced('player-sync-1');

    pending = await repository.getPending();
    expect(pending, isEmpty);
  });

  test('failed entry is hidden until its retry time', () async {
    await repository.enqueue(
      syncId: 'tournament-sync-1',
      entityType: 'tournament',
      entityId: 1,
    );

    await repository.markInProgress('tournament-sync-1');
    await repository.markFailed(
      'tournament-sync-1',
      error: 'offline',
      nextAttemptAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );

    expect(await repository.getPending(), isEmpty);
  });

  test('resetInProgress makes interrupted work pending again', () async {
    await repository.enqueue(
      syncId: 'team-player-sync-1',
      entityType: 'team_player',
      entityId: 1,
    );

    await repository.markInProgress('team-player-sync-1');
    await repository.resetInProgress();

    final pending = await repository.getPending();
    expect(pending.single.status, 'pending');
    expect(pending.single.attempts, 1);
  });

  test('enqueueing an already synced entry makes it pending again', () async {
    await repository.enqueue(
      syncId: 'team-sync-2',
      entityType: 'team',
      entityId: 2,
    );
    await repository.markInProgress('team-sync-2');
    await repository.markSynced('team-sync-2');

    expect(await repository.getPending(), isEmpty);

    await repository.enqueue(
      syncId: 'team-sync-2',
      entityType: 'team',
      entityId: 2,
    );

    final pending = await repository.getPending();
    expect(pending.single.status, 'pending');
    expect(pending.single.attempts, 1);
    expect(pending.single.lastError, isNull);
  });

  test('pending entries are ordered by catalog dependency type', () async {
    await repository.enqueue(syncId: 'tournament-1', entityType: 'tournament', entityId: 1);
    await repository.enqueue(syncId: 'player-1', entityType: 'player', entityId: 1);
    await repository.enqueue(syncId: 'team-player-1', entityType: 'team_player', entityId: 1);
    await repository.enqueue(syncId: 'team-1', entityType: 'team', entityId: 1);

    final pending = await repository.getPending();

    expect(
      pending.map((entry) => entry.entityType).toList(),
      ['team', 'player', 'team_player', 'tournament'],
    );
  });
}
