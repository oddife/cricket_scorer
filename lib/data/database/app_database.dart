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
  AppDatabase({String name = 'cricket_scorer'}) : super(driftDatabase(name: name));

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
          await _createCatalogSyncQueueTable();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await _createWicketEventContextTable();
          }
          if (from < 3) {
            await _createSyncTables();
          }
          if (from < 4) {
            await _createStableSyncIdentityTable();
          }
          if (from < 5) {
            await _createTournamentPointsRulesTable();
          }
          if (from < 6) {
            await _createMatchStatusColumns();
          }
          if (from < 7) {
            await _createMatchTournamentColumn();
          }
          if (from < 8) {
            await _createMatchResultColumns();
          }
          if (from < 9) {
            await _createMatchResultDetailsColumns();
          }
          if (from < 10) {
            await _createInningsResultColumns();
          }
          if (from < 11) {
            await _createBallEventContextColumns();
          }
          if (from < 12) {
            await _createCatalogSyncQueueTable();
          }
        },
      );

  Future<void> _createWicketEventContextTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS wicket_event_context (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ball_event_id INTEGER NOT NULL,
        wicket_type TEXT NOT NULL,
        dismissed_player_id INTEGER NOT NULL,
        fielder_player_id INTEGER,
        fielder_team_id INTEGER,
        run_out_end TEXT,
        catch_type TEXT,
        is_credited_to_bowler INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(ball_event_id) REFERENCES ball_events(id) ON DELETE CASCADE,
        FOREIGN KEY(dismissed_player_id) REFERENCES players(id),
        FOREIGN KEY(fielder_player_id) REFERENCES players(id),
        FOREIGN KEY(fielder_team_id) REFERENCES teams(id)
      )
    ''');
  }

  Future<void> _createSyncTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT NOT NULL UNIQUE,
        innings_id INTEGER NOT NULL,
        sequence_number INTEGER NOT NULL,
        entity_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        next_attempt_at TEXT,
        last_error TEXT,
        synced_at TEXT,
        FOREIGN KEY(innings_id) REFERENCES innings(id) ON DELETE CASCADE
      )
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_pending
      ON sync_queue(status, next_attempt_at, id)
    ''');
  }

  Future<void> _createStableSyncIdentityTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_identity (
        entity_type TEXT NOT NULL,
        local_id INTEGER NOT NULL,
        sync_id TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        PRIMARY KEY(entity_type, local_id)
      )
    ''');
  }

  Future<void> _createTournamentPointsRulesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tournament_points_rules (
        tournament_id INTEGER PRIMARY KEY,
        win_points INTEGER NOT NULL DEFAULT 2,
        tie_points INTEGER NOT NULL DEFAULT 1,
        no_result_points INTEGER NOT NULL DEFAULT 1,
        loss_points INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createMatchStatusColumns() async {
    await customStatement("ALTER TABLE matches ADD COLUMN status INTEGER NOT NULL DEFAULT 0");
  }

  Future<void> _createMatchTournamentColumn() async {
    await customStatement('ALTER TABLE matches ADD COLUMN tournament_id INTEGER');
  }

  Future<void> _createMatchResultColumns() async {
    await customStatement('ALTER TABLE matches ADD COLUMN result TEXT');
    await customStatement('ALTER TABLE matches ADD COLUMN result_team_id INTEGER');
  }

  Future<void> _createMatchResultDetailsColumns() async {
    await customStatement('ALTER TABLE matches ADD COLUMN result_margin INTEGER');
    await customStatement('ALTER TABLE matches ADD COLUMN result_margin_type TEXT');
  }

  Future<void> _createInningsResultColumns() async {
    await customStatement('ALTER TABLE innings ADD COLUMN result TEXT');
  }

  Future<void> _createBallEventContextColumns() async {
    await customStatement('ALTER TABLE ball_events ADD COLUMN striker_id INTEGER');
    await customStatement('ALTER TABLE ball_events ADD COLUMN non_striker_id INTEGER');
    await customStatement('ALTER TABLE ball_events ADD COLUMN bowler_id INTEGER');
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
