import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/data/database/app_database.dart' hide BallEvent;
import 'package:cricket_scorer/data/repositories/drift_ball_event_deletion_repository.dart';
import 'package:cricket_scorer/data/repositories/drift_ball_event_repository.dart';
import 'package:cricket_scorer/data/repositories/drift_entity_identity_repository.dart';
import 'package:cricket_scorer/data/repositories/drift_sync_identity_repository.dart';
import 'package:cricket_scorer/data/repositories/drift_sync_queue_repository.dart';
import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/models/ball_event.dart';

void main() {
  late AppDatabase database;
  late DriftBallEventDeletionRepository deletionRepository;
  late DriftSyncQueueRepository queueRepository;
  late DriftBallEventRepository ballRepository;

  setUp(() async {
    database = AppDatabase(executor: NativeDatabase.memory());
    deletionRepository = DriftBallEventDeletionRepository(database);
    queueRepository = DriftSyncQueueRepository(database);

    final now = DateTime.utc(2026, 10, 19);
    final nowMs = now.millisecondsSinceEpoch;
    await database.customStatement(
      '''INSERT INTO matches
        (name, date, innings_count, overs_per_innings, balls_per_over,
         players_per_team, two_bowler_mode, status, created_at, updated_at)
         VALUES (?, ?, 2, 10, 6, 11, 0, 0, ?, ?)''',
      ['Undo test', nowMs, nowMs, nowMs],
    );
    await database.customStatement(
      '''INSERT INTO innings
        (match_id, innings_number, batting_team_id, bowling_team_id,
         opening_striker_id, opening_non_striker_id, opening_bowler_id,
         overs_per_innings, balls_per_over, two_bowler_mode, status, started_at)
         VALUES (1, 1, 1, 2, 10, 11, 20, 10, 6, 0, 1, ?)''',
      [nowMs],
    );

    ballRepository = DriftBallEventRepository(
      database,
      queueRepository,
      DriftEntityIdentityRepository(database),
      DriftSyncIdentityRepository(database),
      deletionRepository,
    );
  });

  tearDown(() => database.close());

  test('undo persists a tombstone and removes the queued upload and stale identity', () async {
    final event = await ballRepository.create(
      BallEvent(
        id: 0,
        inningsId: 1,
        sequenceNumber: 1,
        overNumber: 1,
        legalBallNumber: 1,
        bowlerId: 20,
        strikerId: 10,
        nonStrikerId: 11,
        deliveryType: DeliveryType.normal,
        isLegalBall: true,
        batterRuns: 1,
        byeRuns: 0,
        legByeRuns: 0,
        wideRuns: 0,
        noBallRuns: 0,
        totalRuns: 1,
        timestamp: DateTime.utc(2026, 10, 19, 12),
      ),
    );


    await DriftSyncIdentityRepository(database)
        .ensureBallEventSyncId(event.id);
    await ballRepository.deleteById(event.id);

    expect(await ballRepository.getForInnings(1), isEmpty);
    expect(await queueRepository.getPending(), isEmpty);

    final deletions = await deletionRepository.getPending();
    expect(deletions, hasLength(1));
    expect(deletions.single.sequenceNumber, 1);
    expect(deletions.single.matchSyncId, isNotEmpty);
    expect(deletions.single.inningsSyncId, isNotEmpty);
    expect(deletions.single.syncId, isNotEmpty);

    final staleIdentity = await database.customSelect(
      '''SELECT sync_id FROM sync_entity_identities
         WHERE entity_type = 'ball' AND local_id = ?''',
      variables: [Variable.withInt(event.id)],
    ).get();
    expect(staleIdentity, isEmpty);
  });

  test('remote tombstone upgrades a pending tombstone to synced', () async {
    await deletionRepository.recordLocalDeletion(
      syncId: 'ball-delete-1',
      matchId: 1,
      inningsId: 1,
      matchSyncId: 'match-1',
      inningsSyncId: 'innings-1',
      sequenceNumber: 1,
      deletedByInstallationId: 'install-1',
    );

    await deletionRepository.recordRemoteDeletion(
      syncId: 'ball-delete-1',
      matchId: 1,
      inningsId: 1,
      matchSyncId: 'match-1',
      inningsSyncId: 'innings-1',
      sequenceNumber: 1,
      deletedByInstallationId: 'install-1',
      deletedAt: DateTime.utc(2026, 10, 19, 12),
    );

    expect(await deletionRepository.getPending(), isEmpty);
    final stored = await deletionRepository.getForMatch(1);
    expect(stored, hasLength(1));
    expect(stored.single.status, 'synced');
  });
}
