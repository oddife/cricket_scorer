import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/catalog_sync_queue_repository.dart';
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
import 'supabase_ball_event_transport.dart';
import 'supabase_match_transport.dart';
import 'supabase_team_player_transport.dart';
import 'supabase_tournament_transport.dart';
import 'sync_retry_policy.dart';

class SyncWorker {
  const SyncWorker({
    required this.syncQueueRepository,
    required this.catalogSyncQueueRepository,
    required this.syncIdentityRepository,
    required this.ballEventRepository,
    required this.inningsRepository,
    required this.matchRepository,
    required this.teamRepository,
    required this.playerRepository,
    required this.teamPlayerRepository,
    required this.tournamentRepository,
    required this.tournamentTeamRepository,
    required this.tournamentPointsRepository,
    required this.transport,
    required this.matchTransport,
    required this.teamPlayerTransport,
    required this.tournamentTransport,
    this.retryPolicy = const SyncRetryPolicy(),
  });

  final SyncQueueRepository syncQueueRepository;
  final CatalogSyncQueueRepository catalogSyncQueueRepository;
  final SyncIdentityRepository syncIdentityRepository;
  final BallEventRepository ballEventRepository;
  final InningsRepository inningsRepository;
  final MatchRepository matchRepository;
  final TeamRepository teamRepository;
  final PlayerRepository playerRepository;
  final TeamPlayerRepository teamPlayerRepository;
  final TournamentRepository tournamentRepository;
  final TournamentTeamRepository tournamentTeamRepository;
  final TournamentPointsRepository tournamentPointsRepository;
  final SupabaseBallEventTransport transport;
  final SupabaseMatchTransport matchTransport;
  final SupabaseTeamPlayerTransport teamPlayerTransport;
  final SupabaseTournamentTransport tournamentTransport;
  final SyncRetryPolicy retryPolicy;

  Future<int> runOnce({int limit = 50}) async {
    await syncQueueRepository.resetInProgress();
    await catalogSyncQueueRepository.resetInProgress();
    final installationId = await syncQueueRepository.ensureInstallationId();

    await _seedCatalogQueue(installationId);
    await _processCatalogQueue(installationId, limit: limit);

    final pending = await syncQueueRepository.getPending(limit: limit);
    var synced = 0;
    final preparedMatches = <String>{};
    final preparedInnings = <String>{};

    for (final entry in pending) {
      await syncQueueRepository.markInProgress(entry.syncId);
      try {
        final innings = await inningsRepository.getById(entry.inningsId);
        if (innings == null) {
          throw StateError('Cannot sync BallEvent ${entry.entityId}: innings ${entry.inningsId} was not found locally.');
        }
        final match = await matchRepository.getById(innings.matchId);
        if (match == null) {
          throw StateError('Cannot sync BallEvent ${entry.entityId}: match ${innings.matchId} was not found locally.');
        }

        final matchSyncId = await syncIdentityRepository.ensureMatchSyncId(match.id);
        final inningsSyncId = await syncIdentityRepository.ensureInningsSyncId(innings.id);
        final ballEventSyncId = await syncIdentityRepository.ensureBallEventSyncId(entry.entityId);
        final tournamentSyncId = match.tournamentId == null
            ? null
            : _tournamentSyncId(installationId, match.tournamentId!);

        if (!preparedMatches.contains(matchSyncId)) {
          await matchTransport.uploadMatch(
            match: match,
            syncId: matchSyncId,
            installationId: installationId,
            tournamentSyncId: tournamentSyncId,
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

        final event = await ballEventRepository.getBySequence(entry.inningsId, entry.sequenceNumber);
        if (event == null || event.id != entry.entityId) {
          throw StateError('Cannot sync queue entry ${entry.syncId}: local BallEvent is missing or does not match the queue.');
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

  Future<void> _seedCatalogQueue(String installationId) async {
    final teams = await teamRepository.getAll();
    for (final team in teams) {
      final syncId = await syncIdentityRepository.ensureTeamSyncId(team.id);
      await catalogSyncQueueRepository.enqueue(
        syncId: syncId,
        entityType: 'team',
        entityId: team.id,
      );
    }

    final players = await playerRepository.getAll();
    for (final player in players) {
      final syncId = await syncIdentityRepository.ensurePlayerSyncId(player.id);
      await catalogSyncQueueRepository.enqueue(
        syncId: syncId,
        entityType: 'player',
        entityId: player.id,
      );
    }

    final memberships = await teamPlayerRepository.getActiveMemberships();
    for (final membership in memberships) {
      final syncId = await syncIdentityRepository.ensureTeamPlayerSyncId(membership.id);
      await catalogSyncQueueRepository.enqueue(
        syncId: syncId,
        entityType: 'team_player',
        entityId: membership.id,
      );
    }

    final tournaments = await tournamentRepository.getAll();
    for (final tournament in tournaments) {
      await catalogSyncQueueRepository.enqueue(
        syncId: _tournamentSyncId(installationId, tournament.id),
        entityType: 'tournament',
        entityId: tournament.id,
      );
    }
  }

  Future<void> _processCatalogQueue(String installationId, {required int limit}) async {
    final teams = {for (final team in await teamRepository.getAll()) team.id: team};
    final players = {for (final player in await playerRepository.getAll()) player.id: player};
    final memberships = {for (final membership in await teamPlayerRepository.getActiveMemberships()) membership.id: membership};
    final tournaments = {for (final tournament in await tournamentRepository.getAll()) tournament.id: tournament};
    final pending = await catalogSyncQueueRepository.getPending(limit: limit);

    for (final entry in pending) {
      await catalogSyncQueueRepository.markInProgress(entry.syncId);
      try {
        switch (entry.entityType) {
          case 'team':
            final team = teams[entry.entityId];
            if (team == null) throw StateError('Catalog team ${entry.entityId} is no longer active locally.');
            await teamPlayerTransport.uploadTeam(
              team: team,
              syncId: entry.syncId,
              installationId: installationId,
            );
            break;
          case 'player':
            final player = players[entry.entityId];
            if (player == null) throw StateError('Catalog player ${entry.entityId} is no longer active locally.');
            await teamPlayerTransport.uploadPlayer(
              player: player,
              syncId: entry.syncId,
              installationId: installationId,
            );
            break;
          case 'team_player':
            final membership = memberships[entry.entityId];
            if (membership == null) throw StateError('Catalog membership ${entry.entityId} is no longer active locally.');
            await teamPlayerTransport.uploadTeamPlayer(
              membership: membership,
              teamSyncId: await syncIdentityRepository.ensureTeamSyncId(membership.teamId),
              playerSyncId: await syncIdentityRepository.ensurePlayerSyncId(membership.playerId),
              syncId: entry.syncId,
              installationId: installationId,
            );
            break;
          case 'tournament':
            final tournament = tournaments[entry.entityId];
            if (tournament == null) throw StateError('Catalog tournament ${entry.entityId} is no longer active locally.');
            await tournamentTransport.uploadTournament(
              tournament: tournament,
              syncId: entry.syncId,
              installationId: installationId,
            );
            final tournamentTeams = await tournamentTeamRepository.getTeams(tournament.id);
            await tournamentTransport.uploadTournamentTeams(
              tournamentSyncId: entry.syncId,
              teams: tournamentTeams,
              teamSyncId: syncIdentityRepository.ensureTeamSyncId,
            );
            final rules = await tournamentPointsRepository.get(tournament.id);
            await tournamentTransport.uploadPointsRules(
              rules: rules,
              tournamentSyncId: entry.syncId,
            );
            break;
          default:
            throw StateError('Unknown catalog sync entity type ${entry.entityType}.');
        }
        await catalogSyncQueueRepository.markSynced(entry.syncId);
      } catch (error) {
        final attempts = entry.attempts + 1;
        await catalogSyncQueueRepository.markFailed(
          entry.syncId,
          error: error.toString(),
          nextAttemptAt: retryPolicy.nextAttemptAt(attempts: attempts),
        );
      }
    }
  }

  String _tournamentSyncId(String installationId, int tournamentId) =>
      '$installationId:tournament:$tournamentId';
}
