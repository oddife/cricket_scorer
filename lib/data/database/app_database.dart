import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/ball_events.dart';
import 'tables/innings.dart';
import 'tables/match_players.dart';
import 'tables/match_teams.dart';
import 'tables/matches.dart';
import 'tables/players.dart';
import 'tables/team_players.dart';
import 'tables/teams.dart';
import 'tables/tournament_teams.dart';
import 'tables/tournaments.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Players,
    Teams,
    TeamPlayers,
    Tournaments,
    TournamentTeams,
    Matches,
    MatchTeams,
    MatchPlayers,
    Innings,
    BallEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'cricket_scorer'));

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createWicketEventContextTable();
          await _createSyncTables();
          await _createStableSyncIdentityTable();
          await _createTournamentPointsRulesTable();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(players);
            await m.createTable(teams);
            await m.createTable(teamPlayers);
          }
          if (from < 3) {
            await m.addColumn(players, players.jerseyNumber);
            await m.addColumn(players, players.battingStyle);
            await m.addColumn(players, players.bowlingStyle);
          }
          if (from < 4) {
            await m.createTable(matches);
            await m.createTable(matchTeams);
            await m.createTable(matchPlayers);
          }
          if (from < 5) {
            await m.createTable(innings);
          }
          if (from < 6) {
            await m.createTable(ballEvents);
          }
          if (from < 7) {
            await _createWicketEventContextTable();
          }
          if (from < 8) {
            await m.createTable(tournamentTeams);
          }
          if (from < 9) {
            await _createSyncTables();
          }
          if (from < 10) {
            await _createStableSyncIdentityTable();
          }
          if (from < 11) {
            await _createTournamentPointsRulesTable();
          }
          if (from < 12) {
            await _createCatalogSyncQueueTable();
          }
        },
      );

  Future<void> _createWicketEventContextTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS wicket_event_contexts (
        ball_event_id INTEGER NOT NULL PRIMARY KEY,
        completed_runs INTEGER NOT NULL DEFAULT 0,
        crossed_before_wicket INTEGER NOT NULL DEFAULT 0,
        replacement_batter_id INTEGER
      )
    ''');
  }

  Future<void> _createSyncTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
        installation_id TEXT NOT NULL UNIQUE
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT NOT NULL UNIQUE,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        innings_id INTEGER NOT NULL,
        sequence_number INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        next_attempt_at TEXT,
        last_error TEXT,
        synced_at TEXT
      )
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_pending
      ON sync_queue(status, next_attempt_at, innings_id, sequence_number)
    ''');
  }

  Future<void> _createStableSyncIdentityTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_entity_identities (
        entity_type TEXT NOT NULL,
        local_id INTEGER NOT NULL,
        sync_id TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        PRIMARY KEY (entity_type, local_id)
      )
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_sync_entity_identities_sync_id
      ON sync_entity_identities(sync_id)
    ''');
  }

  Future<void> _createTournamentPointsRulesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tournament_points_rules (
        tournament_id INTEGER NOT NULL PRIMARY KEY,
        win_points INTEGER NOT NULL DEFAULT 2,
        tie_points INTEGER NOT NULL DEFAULT 1,
        no_result_points INTEGER NOT NULL DEFAULT 1,
        loss_points INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createCatalogSyncQueueTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS catalog_sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT NOT NULL UNIQUE,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        next_attempt_at TEXT,
        last_error TEXT,
        synced_at TEXT
      )
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_catalog_sync_queue_pending
      ON catalog_sync_queue(status, next_attempt_at, entity_type, id)
    ''');
  }
}