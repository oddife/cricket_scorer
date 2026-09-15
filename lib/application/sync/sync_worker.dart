import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../data/repositories/sync_queue_repository.dart';
import 'supabase_ball_event_transport.dart';
import 'sync_retry_policy.dart';

class SyncWorker {
  const SyncWorker({
    required this._syncQueueRepository,
    required this._ballEventRepository,
    required this._inningsRepository,
    required this._transport,
    this._retryPolicy = const SyncRetryPolicy(),
  });

  final SyncQueueRepository _syncQueueRepository;
  final BallEventRepository _ballEventRepository;
  final InningsRepository _inningsRepository;
  final SupabaseBallEventTransport _transport;
  final SyncRetryPolicy _retryPolicy;

  Future<int> runOnce({int limit = 50}) async {
    await _syncQueueRepository.resetInProgress();
    final installationId = await _syncQueueRepository.ensureInstallationId();
    final pending = await _syncQueueRepository.getPending(limit: limit);
    var synced = 0;

    for (final entry in pending) {
      await _syncQueueRepository.markInProgress(entry.syncId);
      try {
        final innings = await _inningsRepository.getById(entry.inningsId);
        if (innings == null) {
          throw StateError(
            'Cannot sync BallEvent ${entry.entityId}: innings ${entry.inningsId} was not found locally.',
          );
        }

        final event = await _ballEventRepository.getBySequence(
          entry.inningsId,
          entry.sequenceNumber,
        );
        if (event == null || event.id != entry.entityId) {
          throw StateError(
            'Cannot sync queue entry ${entry.syncId}: local BallEvent is missing or does not match the queue.',
          );
        }

        await _transport.uploadBallEvent(
          event: event,
          installationId: installationId,
          matchId: innings.matchId,
        );
        await _syncQueueRepository.markSynced(entry.syncId);
        synced++;
      } catch (error) {
        final attempts = entry.attempts + 1;
        await _syncQueueRepository.markFailed(
          entry.syncId,
          error: error.toString(),
          nextAttemptAt: _retryPolicy.nextAttemptAt(attempts: attempts),
        );
      }
    }

    return synced;
  }
}
