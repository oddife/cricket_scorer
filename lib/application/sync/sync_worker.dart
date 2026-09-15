import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/sync_queue_repository.dart';
import 'supabase_ball_event_transport.dart';
import 'supabase_match_transport.dart';
import 'sync_retry_policy.dart';

class SyncWorker {
  const SyncWorker({
    required this._syncQueueRepository,
    required this._ballEventRepository,
    required this._inningsRepository,
    required this._matchRepository,
    required this._transport,
    required this._matchTransport,
    this._retryPolicy = const SyncRetryPolicy(),
  });

  final SyncQueueRepository _syncQueueRepository;
  final BallEventRepository _ballEventRepository;
  final InningsRepository _inningsRepository;
  final MatchRepository _matchRepository;
  final SupabaseBallEventTransport _transport;
  final SupabaseMatchTransport _matchTransport;
  final SyncRetryPolicy _retryPolicy;

  Future<int> runOnce({int limit = 50}) async {
    await _syncQueueRepository.resetInProgress();
    final installationId = await _syncQueueRepository.ensureInstallationId();
    final pending = await _syncQueueRepository.getPending(limit: limit);
    var synced = 0;
    final preparedMatches = <int>{};
    final preparedInnings = <int>{};

    for (final entry in pending) {
      await _syncQueueRepository.markInProgress(entry.syncId);
      try {
        final innings = await _inningsRepository.getById(entry.inningsId);
        if (innings == null) {
          throw StateError(
            'Cannot sync BallEvent ${entry.entityId}: innings ${entry.inningsId} was not found locally.',
          );
        }

        final match = await _matchRepository.getById(innings.matchId);
        if (match == null) {
          throw StateError(
            'Cannot sync BallEvent ${entry.entityId}: match ${innings.matchId} was not found locally.',
          );
        }

        if (!preparedMatches.contains(match.id)) {
          await _matchTransport.uploadMatch(
            match: match,
            installationId: installationId,
          );
          preparedMatches.add(match.id);
        }

        if (!preparedInnings.contains(innings.id)) {
          await _matchTransport.uploadInnings(
            innings: innings,
            match: match,
            installationId: installationId,
          );
          preparedInnings.add(innings.id);
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
