import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/database_provider.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/sync_identity_repository.dart';

class PermanentDeleteService {
  const PermanentDeleteService({
    required this.database,
    required this.client,
    required this.syncIdentityRepository,
  });

  final AppDatabase database;
  final SupabaseClient? client;
  final SyncIdentityRepository syncIdentityRepository;

  Future<void> deleteMatch(int matchId) async {
    final syncId = await syncIdentityRepository.ensureMatchSyncId(matchId);
    await _remoteDelete('match', syncId);

    await database.transaction(() async {
      await database.customStatement(
        "DELETE FROM sync_entity_identities WHERE entity_type = 'ball' AND local_id IN "
        '(SELECT id FROM ball_events WHERE innings_id IN '
        '(SELECT id FROM innings WHERE match_id = ?))',
        [matchId],
      );
      await database.customStatement(
        "DELETE FROM sync_entity_identities WHERE entity_type = 'innings' AND local_id IN "
        '(SELECT id FROM innings WHERE match_id = ?)',
        [matchId],
      );
      await database.customStatement(
        "DELETE FROM sync_entity_identities WHERE entity_type = 'match' AND local_id = ?",
        [matchId],
      );
      await database.customStatement(
        'DELETE FROM ball_events WHERE innings_id IN '
        '(SELECT id FROM innings WHERE match_id = ?)',
        [matchId],
      );
      await database.customStatement(
        'DELETE FROM wicket_event_contexts WHERE ball_event_id NOT IN '
        '(SELECT id FROM ball_events)',
      );
      await (database.delete(database.innings)
            ..where((row) => row.matchId.equals(matchId)))
          .go();
      await (database.delete(database.matchPlayers)
            ..where((row) => row.matchId.equals(matchId)))
          .go();
      await (database.delete(database.matchTeams)
            ..where((row) => row.matchId.equals(matchId)))
          .go();
      await (database.delete(database.matches)
            ..where((row) => row.id.equals(matchId)))
          .go();
    });
  }

  Future<void> deletePlayer(int playerId) async {
    final syncId = await syncIdentityRepository.ensurePlayerSyncId(playerId);
    await _remoteDelete('player', syncId);
    await database.transaction(() async {
      await (database.delete(database.teamPlayers)
            ..where((row) => row.playerId.equals(playerId)))
          .go();
      await (database.delete(database.players)
            ..where((row) => row.id.equals(playerId)))
          .go();
      await database.customStatement(
        "DELETE FROM sync_entity_identities WHERE entity_type = 'player' AND local_id = ?",
        [playerId],
      );
    });
  }

  Future<void> deleteTeam(int teamId) async {
    final syncId = await syncIdentityRepository.ensureTeamSyncId(teamId);
    await _remoteDelete('team', syncId);
    await database.transaction(() async {
      await (database.delete(database.tournamentTeams)
            ..where((row) => row.teamId.equals(teamId)))
          .go();
      await (database.delete(database.teamPlayers)
            ..where((row) => row.teamId.equals(teamId)))
          .go();
      await (database.delete(database.teams)
            ..where((row) => row.id.equals(teamId)))
          .go();
      await database.customStatement(
        "DELETE FROM sync_entity_identities WHERE entity_type = 'team' AND local_id = ?",
        [teamId],
      );
    });
  }

  Future<void> deleteTournament(int tournamentId) async {
    final syncId = await syncIdentityRepository.ensureTournamentSyncId(tournamentId);
    await _remoteDelete('tournament', syncId);
    await database.transaction(() async {
      await database.customStatement(
        'UPDATE matches SET tournament_id = NULL WHERE tournament_id = ?',
        [tournamentId],
      );
      await database.customStatement(
        'DELETE FROM tournament_points_rules WHERE tournament_id = ?',
        [tournamentId],
      );
      await (database.delete(database.tournamentTeams)
            ..where((row) => row.tournamentId.equals(tournamentId)))
          .go();
      await (database.delete(database.tournaments)
            ..where((row) => row.id.equals(tournamentId)))
          .go();
      await database.customStatement(
        "DELETE FROM sync_entity_identities WHERE entity_type = 'tournament' AND local_id = ?",
        [tournamentId],
      );
    });
  }

  Future<void> _remoteDelete(String entityType, String syncId) async {
    final supabase = client;
    if (supabase == null || supabase.auth.currentUser == null) {
      throw StateError(
        'Permanent deletion requires an authenticated Supabase connection.',
      );
    }

    await supabase.rpc<void>(
      'permanently_delete_catalog_entity',
      params: <String, dynamic>{
        'p_entity_type': entityType,
        'p_sync_id': syncId,
      },
    );
  }
}

final permanentDeleteServiceProvider = Provider<PermanentDeleteService>((ref) {
  return PermanentDeleteService(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    syncIdentityRepository: ref.watch(syncIdentityRepositoryProvider),
  );
});
