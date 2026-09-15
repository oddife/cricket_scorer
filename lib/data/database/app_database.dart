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
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createWicketEventContextTable();
          await _createSyncTables();
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
}
