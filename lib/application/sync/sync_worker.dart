import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/sync_identity_repository.dart';
import '../../data/repositories/sync_queue_repository.dart';
import '../../data/repositories/team_player_repository.dart';
import '../../data/repositories/team_repository.dart';
import 'supabase_ball_event_transport.dart';
import 'supabase_match_transport.dart';
import 'supabase_team_player_transport.dart';
import 'sync_retry_policy.dart';

class SyncWorker {
  const SyncWorker({
    required this.syncQueueRepository,
    required this.syncIdentityRepository,
    required this.ballEventRepository,
    required this.inningsRepository,
    required this.matchRepository,
    required this.teamRepository,
    required this.playerRepository,
    required this.teamPlayerRepository,
    required this.transport,
    required this.matchTransport,
    required this.teamPlayerTransport,
    this.retryPolicy = const SyncRetryPolicy(),
  });

  final SyncQueueRepository syncQueueRepository;
  final SyncIdentityRepository syncIdentityRepository;
  final BallEventRepository ballEventRepository;
  final InningsRepository inningsRepository;
  final MatchRepository matchRepository;
  final TeamRepository teamRepository;
  final PlayerRepository playerRepository;
  final TeamPlayerRepository teamPlayerRepository;
  final SupabaseBallEventTransport transport;
  final SupabaseMatchTransport matchTransport;
  final SupabaseTeamPlayerTransport teamPlayerTransport;
  final SyncRetryPolicy retryPolicy;

  Future<int> runOnce({int limit = 50}) async {
    await syncQueueRepository.resetInProgress();
    final installationId = await syncQueueRepository.ensureInstallationId();
    final pending = await syncQueueRepository.getPending(limit: limit);
    var synced = 0;
    final preparedCatalog = <String>{};
    final preparedMatches = <String>{};
    final preparedInnings = <String>{};

    for (final entry in pending) {
      await syncQueueRepository.markInProgress(entry.syncId);
      try {
        final innings = await inningsRepository.getById(entry.inningsId);
        if (innings == null) {
          throw StateError(
            'Cannot sync BallEvent ${entry.entityId}: innings ${entry.inningsId} was not found locally.',
          );
        }

        final match = await matchRepository.getById(innings.matchId);
        if (match == null) {
          throw StateError(
            'Cannot sync BallEvent ${entry.entityId}: match ${innings.matchId} was not found locally.',
          );
        }

        if (preparedCatalog.isEmpty) {
          await _uploadCatalog(installationId);
          preparedCatalog.add('uploaded');
        }

        final matchSyncId = await syncIdentityRepository.ensureMatchSyncId(match.id);
        final inningsSyncId = await syncIdentityRepository.ensureInningsSyncId(innings.id);
        final ballEventSyncId = await syncIdentityRepository.ensureBallEventSyncId(entry.entityId);

        if (!preparedMatches.contains(matchSyncId)) {
          await matchTransport.uploadMatch(
            match: match,
            syncId: matchSyncId,
            installationId: installationId,
          );

          final matchTeams = await matchRepository.getTeams(match.id);
          await matchTransport.uploadMatchTeams(
            matchSyncId: matchSyncId,
            teams: matchTeams,
            teamSyncId: syncIdentityRepository.ensureTeamSyncId,
          );

          final matchPlayers = await matchRepository.getPlayers(match.id);
          await matchTransport.uploadMatchPlayers(
            matchSyncId: matchSyncId,
            players: matchPlayers,
            teamSyncId: syncIdentityRepository.ensureTeamSyncId,
            playerSyncId: syncIdentityRepository.ensurePlayerSyncId,
          );

          preparedMatches.add(matchSyncId);
        }

        if (!preparedInnings.contains(inningsSyncId)) {
          await matchTransport.uploadInnings(
            innings: innings,
            matchSyncId: matchSyncId,
            syncId: inningsSyncId,
            installationId: installationId,
          );
          preparedInnings.add(inningsSyncId);
        }

        final event = await ballEventRepository.getBySequence(
          entry.inningsId,
          entry.sequenceNumber,
        );
        if (event == null || event.id != entry.entityId) {
          throw StateError(
            'Cannot sync queue entry ${entry.syncId}: local BallEvent is missing or does not match the queue.',
          );
        }

        await transport.uploadBallEvent(
          event: event,
          syncId: ballEventSyncId,
          matchSyncId: matchSyncId,
          inningsSyncId: inningsSyncId,
          installationId: installationId,
        );
        await syncQueueRepository.markSynced(entry.syncId);
        synced++;
      } catch (error) {
        final attempts = entry.attempts + 1;
        await syncQueueRepository.markFailed(
          entry.syncId,
          error: error.toString(),
          nextAttemptAt: retryPolicy.nextAttemptAt(attempts: attempts),
        );
      }
    }

    return synced;
  }

  Future<void> _uploadCatalog(String installationId) async {
    final teams = await teamRepository.getAll();
    for (final team in teams) {
      final syncId = await syncIdentityRepository.ensureTeamSyncId(team.id);
      await teamPlayerTransport.uploadTeam(
        team: team,
        syncId: syncId,
        installationId: installationId,
      );
    }

    final players = await playerRepository.getAll();
    for (final player in players) {
      final syncId = await syncIdentityRepository.ensurePlayerSyncId(player.id);
      await teamPlayerTransport.uploadPlayer(
        player: player,
        syncId: syncId,
        installationId: installationId,
      );
    }

    final memberships = await teamPlayerRepository.getActiveMemberships();
    for (final membership in memberships) {
      final teamSyncId = await syncIdentityRepository.ensureTeamSyncId(membership.teamId);
      final playerSyncId = await syncIdentityRepository.ensurePlayerSyncId(membership.playerId);
      final syncId = await syncIdentityRepository.ensureTeamPlayerSyncId(membership.id);
      await teamPlayerTransport.uploadTeamPlayer(
        membership: membership,
        teamSyncId: teamSyncId,
        playerSyncId: playerSyncId,
        syncId: syncId,
        installationId: installationId,
      );
    }
  }
}
