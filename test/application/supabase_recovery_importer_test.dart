import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/application/sync/supabase_recovery_importer.dart';
import 'package:cricket_scorer/application/sync/supabase_recovery_transport.dart';
import 'package:cricket_scorer/data/database/app_database.dart';

void main() {
  late AppDatabase database;
  late SupabaseRecoveryImporter importer;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    importer = SupabaseRecoveryImporter(database);
  });

  tearDown(() => database.close());

  test('recovery rejects divergent tournament points and rolls back the import', () async {
    final timestamp = DateTime.utc(2026, 9, 16);
    final now = timestamp.toIso8601String();
    final dbNow = timestamp.millisecondsSinceEpoch;

    await database.customStatement('''
      INSERT INTO tournaments
        (name, tournament_type, logo_path, start_date, end_date, is_active, created_at, updated_at)
      VALUES ('Local Tournament', 0, NULL, NULL, NULL, 1, ?, ?)
    ''', [dbNow, dbNow]);
    await database.customStatement('''
      INSERT INTO sync_entity_identities
        (entity_type, local_id, sync_id, created_at)
      VALUES ('tournament', 1, 'tournament-1', ?)
    ''', [dbNow]);
    await database.customStatement('''
      INSERT INTO tournament_points_rules
        (tournament_id, win_points, tie_points, no_result_points, loss_points)
      VALUES (1, 3, 1, 1, 0)
    ''');

    final snapshot = RemoteMatchSnapshot(
      match: {
        'sync_id': 'match-1',
        'tournament_sync_id': 'tournament-1',
        'name': 'Recovered Match',
        'date': now,
        'venue': null,
        'innings_count': 2,
        'overs_per_innings': 10,
        'balls_per_over': 6,
        'players_per_team': 11,
        'two_bowler_mode': false,
        'toss_winner_team_id': null,
        'toss_decision': null,
        'status': 0,
        'created_at': now,
        'updated_at': now,
      },
      innings: const [],
      ballEvents: const [],
      teams: [
        {
          'sync_id': 'team-a',
          'source_installation_id': 'source-1',
          'local_id': 1,
          'name': 'Team A',
          'short_name': 'A',
          'logo_path': null,
          'is_active': true,
          'updated_at': now,
        },
        {
          'sync_id': 'team-b',
          'source_installation_id': 'source-1',
          'local_id': 2,
          'name': 'Team B',
          'short_name': 'B',
          'logo_path': null,
          'is_active': true,
          'updated_at': now,
        },
      ],
      players: const [],
      teamPlayers: const [],
      matchTeams: [
        {'team_sync_id': 'team-a', 'slot': 0},
        {'team_sync_id': 'team-b', 'slot': 1},
      ],
      matchPlayers: const [],
      tournament: {
        'sync_id': 'tournament-1',
        'name': 'Local Tournament',
        'tournament_type': 0,
        'logo_path': null,
        'start_date': null,
        'end_date': null,
        'is_active': true,
        'updated_at': now,
      },
      tournamentTeams: const [],
      tournamentPointsRules: {
        'tournament_sync_id': 'tournament-1',
        'win_points': 2,
        'tie_points': 1,
        'no_result_points': 1,
        'loss_points': 0,
      },
    );

    await expectLater(
      importer.importMatch(snapshot),
      throwsA(isA<StateError>()),
    );

    final rules = await database.customSelect(
      'SELECT win_points, tie_points, no_result_points, loss_points FROM tournament_points_rules WHERE tournament_id = 1',
    ).getSingle();
    expect(rules.data['win_points'], 3);
    expect(rules.data['tie_points'], 1);
    expect(rules.data['no_result_points'], 1);
    expect(rules.data['loss_points'], 0);

    final matches = await database.customSelect('SELECT COUNT(*) AS count FROM matches').getSingle();
    expect(matches.data['count'], 0);
  });
}
