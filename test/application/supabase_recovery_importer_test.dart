import 'package:drift/drift.dart';
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

  test('recovery reconciles stale local match metadata from the shared snapshot', () async {
    final timestamp = DateTime.utc(2026, 10, 1, 12);
    final now = timestamp.toIso8601String();

    final teamAId = await database.into(database.teams).insert(
      TeamsCompanion.insert(
        name: 'Team A',
        shortName: 'A',
        isActive: const Value(true),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    final teamBId = await database.into(database.teams).insert(
      TeamsCompanion.insert(
        name: 'Team B',
        shortName: 'B',
        isActive: const Value(true),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    final matchId = await database.into(database.matches).insert(
      MatchesCompanion.insert(
        name: 'Old Local Name',
        date: timestamp,
        venue: const Value('Old Venue'),
        inningsCount: 2,
        oversPerInnings: 10,
        ballsPerOver: 6,
        playersPerTeam: 11,
        twoBowlerMode: const Value(false),
        status: const Value(0),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    for (final entry in [
      ('team', teamAId, 'team-a'),
      ('team', teamBId, 'team-b'),
      ('match', matchId, 'match-1'),
    ]) {
      await database.customStatement(
        '''INSERT INTO sync_entity_identities
          (entity_type, local_id, sync_id, created_at)
          VALUES (?, ?, ?, ?)''',
        [entry.$1, entry.$2, entry.$3, now],
      );
    }
    await database.into(database.matchTeams).insert(
      MatchTeamsCompanion.insert(
        matchId: matchId,
        teamId: teamAId,
        slot: 0,
      ),
    );
    await database.into(database.matchTeams).insert(
      MatchTeamsCompanion.insert(
        matchId: matchId,
        teamId: teamBId,
        slot: 1,
      ),
    );

    final snapshot = RemoteMatchSnapshot(
      match: {
        'sync_id': 'match-1',
        'tournament_sync_id': null,
        'name': 'Shared Match Name',
        'date': now,
        'venue': 'Shared Venue',
        'innings_count': 2,
        'overs_per_innings': 12,
        'balls_per_over': 6,
        'players_per_team': 11,
        'two_bowler_mode': false,
        'toss_winner_team_id': null,
        'toss_decision': null,
        'status': 1,
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
      matchTeams: const [
        {'team_sync_id': 'team-a', 'slot': 0},
        {'team_sync_id': 'team-b', 'slot': 1},
      ],
      matchPlayers: const [],
    );

    await importer.importMatch(snapshot);

    final updated = await (database.select(database.matches)
          ..where((match) => match.id.equals(matchId)))
        .getSingle();
    expect(updated.name, 'Shared Match Name');
    expect(updated.venue, 'Shared Venue');
    expect(updated.oversPerInnings, 12);
    expect(updated.status, 1);
  });


  test('recovery resolves ball player references by canonical global ID', () async {
    final timestamp = DateTime.utc(2026, 10, 2, 12);
    final now = timestamp.toIso8601String();
    final match = {
      'sync_id': 'match-global-player-test',
      'tournament_sync_id': null,
      'name': 'Global Player References',
      'date': now,
      'venue': null,
      'innings_count': 2,
      'overs_per_innings': 10,
      'balls_per_over': 6,
      'players_per_team': 11,
      'two_bowler_mode': false,
      // Deliberately invalid as an origin-local ID: the canonical team ID
      // below must be used to recover the toss winner.
      'toss_winner_team_id': 99,
      'toss_winner_team_global_id': 'global-team-a',
      'toss_decision': null,
      'status': 1,
      'created_at': now,
      'updated_at': now,
      'source_installation_id': 'origin-install',
      'local_id': 1,
    };

    final teams = <Map<String, dynamic>>[
      {
        'sync_id': 'team-global-a',
        'global_id': 'global-team-a',
        'source_installation_id': 'origin-install',
        'local_id': 1,
        'name': 'Team A',
        'short_name': 'A',
        'logo_path': null,
        'is_active': true,
        'updated_at': now,
      },
      {
        'sync_id': 'team-global-b',
        'global_id': 'global-team-b',
        'source_installation_id': 'origin-install',
        'local_id': 2,
        'name': 'Team B',
        'short_name': 'B',
        'logo_path': null,
        'is_active': true,
        'updated_at': now,
      },
    ];
    final players = <Map<String, dynamic>>[
      {
        'sync_id': 'player-global-striker',
        'global_id': 'global-striker',
        'source_installation_id': 'origin-install',
        'local_id': 10,
        'name': 'Striker',
        'display_name': 'Striker',
        'photo_path': null,
        'jersey_number': null,
        'batting_style': 0,
        'bowling_style': 0,
        'is_active': true,
        'created_at': now,
        'updated_at': now,
      },
      {
        'sync_id': 'player-global-non-striker',
        'global_id': 'global-non-striker',
        'source_installation_id': 'origin-install',
        'local_id': 11,
        'name': 'Non Striker',
        'display_name': 'Non Striker',
        'photo_path': null,
        'jersey_number': null,
        'batting_style': 0,
        'bowling_style': 0,
        'is_active': true,
        'created_at': now,
        'updated_at': now,
      },
      {
        'sync_id': 'player-global-bowler',
        'global_id': 'global-bowler',
        'source_installation_id': 'origin-install',
        'local_id': 20,
        'name': 'Bowler',
        'display_name': 'Bowler',
        'photo_path': null,
        'jersey_number': null,
        'batting_style': 0,
        'bowling_style': 0,
        'is_active': true,
        'created_at': now,
        'updated_at': now,
      },
    ];

    final snapshot = RemoteMatchSnapshot(
      match: match,
      innings: [
        {
          'sync_id': 'innings-global-player-test',
          'source_installation_id': 'origin-install',
          'local_id': 1,
          'match_sync_id': 'match-global-player-test',
          'innings_number': 1,
          // These local IDs do not match the team's/player catalog source
          // rows on purpose; recovery must prefer canonical global IDs.
          'batting_team_id': 77,
          'bowling_team_id': 78,
          'batting_team_global_id': 'global-team-a',
          'bowling_team_global_id': 'global-team-b',
          'opening_striker_id': 90,
          'opening_non_striker_id': 91,
          'opening_bowler_id': 92,
          'opening_striker_global_id': 'global-striker',
          'opening_non_striker_global_id': 'global-non-striker',
          'opening_bowler_global_id': 'global-bowler',
          'overs_per_innings': 10,
          'balls_per_over': 6,
          'two_bowler_mode': false,
          'status': 'live',
          'started_at': now,
          'completed_at': null,
        },
      ],
      ballEvents: [
        {
          'sync_id': 'ball-global-player-test',
          'source_installation_id': 'android-install',
          'local_id': 99,
          'innings_sync_id': 'innings-global-player-test',
          'sequence_number': 1,
          'over_number': 1,
          'legal_ball_number': 1,
          // These values intentionally collide with neither the originating
          // player's local IDs nor the IDs in the current device's database.
          'bowler_id': 90,
          'striker_id': 91,
          'non_striker_id': 92,
          'bowler_global_id': 'global-bowler',
          'striker_global_id': 'global-striker',
          'non_striker_global_id': 'global-non-striker',
          'delivery_type': 0,
          'is_legal_ball': true,
          'batter_runs': 4,
          'bye_runs': 0,
          'leg_bye_runs': 0,
          'wide_runs': 0,
          'no_ball_runs': 0,
          'total_runs': 4,
          'wicket_type': null,
          'dismissed_player_id': null,
          'fielder_id': null,
          'dismissed_player_global_id': null,
          'fielder_global_id': null,
          'run_out_end': null,
          'credited_to_bowler': null,
          'wicket_completed_runs': 0,
          'wicket_crossed_before_wicket': false,
          'replacement_batter_id': null,
          'replacement_batter_global_id': null,
          'event_timestamp': now,
        },
      ],
      teams: teams,
      players: players,
      teamPlayers: const [],
      // Canonical relationship IDs must be sufficient when old sync-ID
      // columns are null on partially upgraded remote rows.
      matchTeams: const [
        {
          'team_sync_id': 'stale-team-sync-a',
          'team_global_id': 'global-team-a',
          'slot': 0,
        },
        {
          'team_sync_id': 'stale-team-sync-b',
          'team_global_id': 'global-team-b',
          'slot': 1,
        },
      ],
      matchPlayers: const [
        {
          'team_sync_id': 'stale-team-sync-a',
          'player_sync_id': 'stale-player-sync-striker',
          'team_global_id': 'global-team-a',
          'player_global_id': 'global-striker',
          'is_playing': true,
          'batting_order': 1,
        },
        {
          'team_sync_id': 'stale-team-sync-a',
          'player_sync_id': 'stale-player-sync-non-striker',
          'team_global_id': 'global-team-a',
          'player_global_id': 'global-non-striker',
          'is_playing': true,
          'batting_order': 2,
        },
        {
          'team_sync_id': 'stale-team-sync-b',
          'player_sync_id': 'stale-player-sync-bowler',
          'team_global_id': 'global-team-b',
          'player_global_id': 'global-bowler',
          'is_playing': true,
          'batting_order': 1,
        },
      ],
    );

    await importer.importMatch(snapshot);

    Future<int> localPlayerId(String syncId) async {
      final row = await database.customSelect(
        '''SELECT local_id FROM sync_entity_identities
           WHERE entity_type = 'player' AND sync_id = ?''',
        variables: [Variable.withString(syncId)],
      ).getSingle();
      return row.read<int>('local_id');
    }

    Future<int> localTeamId(String syncId) async {
      final row = await database.customSelect(
        '''SELECT local_id FROM sync_entity_identities
           WHERE entity_type = 'team' AND sync_id = ?''',
        variables: [Variable.withString(syncId)],
      ).getSingle();
      return row.read<int>('local_id');
    }

    final matchRow = await database.select(database.matches).getSingle();
    expect(matchRow.tossWinnerTeamId, await localTeamId('team-global-a'));

    final inningsRow = await database.select(database.innings).getSingle();
    expect(inningsRow.battingTeamId, await localTeamId('team-global-a'));
    expect(inningsRow.bowlingTeamId, await localTeamId('team-global-b'));
    expect(
      inningsRow.openingStrikerId,
      await localPlayerId('player-global-striker'),
    );
    expect(
      inningsRow.openingNonStrikerId,
      await localPlayerId('player-global-non-striker'),
    );
    expect(
      inningsRow.openingBowlerId,
      await localPlayerId('player-global-bowler'),
    );

    final ball = await database.select(database.ballEvents).getSingle();
    expect(ball.bowlerId, await localPlayerId('player-global-bowler'));
    expect(ball.strikerId, await localPlayerId('player-global-striker'));
    expect(
      ball.nonStrikerId,
      await localPlayerId('player-global-non-striker'),
    );
    expect(ball.batterRuns, 4);
  });

  test('legacy recovery resolves innings teams when player assignments are absent', () async {
    final timestamp = DateTime.utc(2026, 10, 3, 12);
    final now = timestamp.toIso8601String();

    final snapshot = RemoteMatchSnapshot(
      match: {
        'sync_id': 'legacy-match',
        'source_installation_id': 'origin-install',
        'local_id': 1,
        'tournament_sync_id': null,
        'name': 'Legacy Match',
        'date': now,
        'venue': null,
        'innings_count': 2,
        'overs_per_innings': 10,
        'balls_per_over': 6,
        'players_per_team': 11,
        'two_bowler_mode': false,
        'toss_winner_team_id': null,
        'toss_decision': null,
        'status': 1,
        'created_at': now,
        'updated_at': now,
      },
      teams: [
        {
          'sync_id': 'legacy-team-a',
          'source_installation_id': 'origin-install',
          'local_id': 1,
          'name': 'Team A',
          'short_name': 'A',
          'logo_path': null,
          'is_active': true,
          'updated_at': now,
        },
        {
          'sync_id': 'legacy-team-b',
          'source_installation_id': 'origin-install',
          'local_id': 2,
          'name': 'Team B',
          'short_name': 'B',
          'logo_path': null,
          'is_active': true,
          'updated_at': now,
        },
      ],
      players: [
        for (final player in [
          (id: 10, syncId: 'legacy-striker', name: 'Striker'),
          (id: 11, syncId: 'legacy-non-striker', name: 'Non Striker'),
          (id: 20, syncId: 'legacy-bowler', name: 'Bowler'),
        ])
          {
            'sync_id': player.syncId,
            'source_installation_id': 'origin-install',
            'local_id': player.id,
            'name': player.name,
            'display_name': player.name,
            'photo_path': null,
            'jersey_number': null,
            'batting_style': 0,
            'bowling_style': 0,
            'is_active': true,
            'created_at': now,
            'updated_at': now,
          },
      ],
      innings: [
        {
          'sync_id': 'legacy-innings',
          'source_installation_id': 'origin-install',
          'local_id': 1,
          'match_sync_id': 'legacy-match',
          'innings_number': 1,
          'batting_team_id': 1,
          'bowling_team_id': 2,
          'opening_striker_id': 10,
          'opening_non_striker_id': 11,
          'opening_bowler_id': 20,
          'active_two_bowler_one_id': null,
          'active_two_bowler_two_id': null,
          'overs_per_innings': 10,
          'balls_per_over': 6,
          'two_bowler_mode': false,
          'status': 'live',
          'started_at': now,
          'completed_at': null,
        },
      ],
      ballEvents: const [],
      teamPlayers: const [],
      matchTeams: const [
        {'team_sync_id': 'legacy-team-a', 'slot': 0},
        {'team_sync_id': 'legacy-team-b', 'slot': 1},
      ],
      // Older or partially migrated snapshots can lack these assignments.
      matchPlayers: const [],
    );

    await importer.importMatch(snapshot);

    final recoveredInnings = await database.select(database.innings).getSingle();
    final teamA = await database.customSelect(
      "SELECT local_id FROM sync_entity_identities WHERE entity_type = 'team' AND sync_id = 'legacy-team-a'",
    ).getSingle();
    final teamB = await database.customSelect(
      "SELECT local_id FROM sync_entity_identities WHERE entity_type = 'team' AND sync_id = 'legacy-team-b'",
    ).getSingle();

    expect(recoveredInnings.battingTeamId, teamA.read<int>('local_id'));
    expect(recoveredInnings.bowlingTeamId, teamB.read<int>('local_id'));
  });


  test('recovery reports precise context when legacy innings team IDs are missing', () async {
    final timestamp = DateTime.utc(2026, 10, 4, 12);
    final now = timestamp.toIso8601String();

    final snapshot = RemoteMatchSnapshot(
      match: {
        'sync_id': 'match-null-team-reference',
        'source_installation_id': 'origin-install',
        'local_id': 1,
        'tournament_sync_id': null,
        'name': 'Missing Team Reference',
        'date': now,
        'venue': null,
        'innings_count': 2,
        'overs_per_innings': 10,
        'balls_per_over': 6,
        'players_per_team': 11,
        'two_bowler_mode': false,
        'toss_winner_team_id': null,
        'toss_decision': null,
        'status': 1,
        'created_at': now,
        'updated_at': now,
      },
      teams: [
        {
          'sync_id': 'missing-ref-team-a',
          'source_installation_id': 'origin-install',
          'local_id': 1,
          'name': 'Team A',
          'short_name': 'A',
          'logo_path': null,
          'is_active': true,
          'updated_at': now,
        },
        {
          'sync_id': 'missing-ref-team-b',
          'source_installation_id': 'origin-install',
          'local_id': 2,
          'name': 'Team B',
          'short_name': 'B',
          'logo_path': null,
          'is_active': true,
          'updated_at': now,
        },
      ],
      players: [
        for (final player in [
          (id: 10, syncId: 'missing-ref-striker', name: 'Striker'),
          (id: 11, syncId: 'missing-ref-non-striker', name: 'Non Striker'),
          (id: 20, syncId: 'missing-ref-bowler', name: 'Bowler'),
        ])
          {
            'sync_id': player.syncId,
            'source_installation_id': 'origin-install',
            'local_id': player.id,
            'name': player.name,
            'display_name': player.name,
            'photo_path': null,
            'jersey_number': null,
            'batting_style': 0,
            'bowling_style': 0,
            'is_active': true,
            'created_at': now,
            'updated_at': now,
          },
      ],
      teamPlayers: const [],
      matchTeams: const [
        {'team_sync_id': 'missing-ref-team-a', 'slot': 0},
        {'team_sync_id': 'missing-ref-team-b', 'slot': 1},
      ],
      matchPlayers: const [],
      innings: [
        {
          'sync_id': 'innings-null-team-reference',
          'source_installation_id': 'origin-install',
          'local_id': 1,
          'match_sync_id': 'match-null-team-reference',
          'innings_number': 1,
          'batting_team_id': null,
          'bowling_team_id': null,
          'batting_team_global_id': null,
          'bowling_team_global_id': null,
          'opening_striker_id': 10,
          'opening_non_striker_id': 11,
          'opening_bowler_id': 20,
          'active_two_bowler_one_id': null,
          'active_two_bowler_two_id': null,
          'overs_per_innings': 10,
          'balls_per_over': 6,
          'two_bowler_mode': false,
          'status': 'live',
          'started_at': now,
          'completed_at': null,
        },
      ],
      ballEvents: const [],
    );

    await expectLater(
      importer.importMatch(snapshot),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('innings-null-team-reference'),
            contains('match-null-team-reference'),
            contains('batting_team_id'),
          ),
        ),
      ),
    );

    final matchCount = await database
        .customSelect('SELECT COUNT(*) AS count FROM matches')
        .getSingle();
    expect(matchCount.read<int>('count'), 0);
  });

}
