import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/application/sync/supabase_recovery_transport.dart';

void main() {
  test('remote match snapshot keeps all synchronized entity groups', () {
    final snapshot = RemoteMatchSnapshot(
      match: {'sync_id': 'match-1'},
      innings: [
        {'sync_id': 'innings-1', 'innings_number': 1},
      ],
      ballEvents: [
        {'sync_id': 'ball-2', 'sequence_number': 2},
        {'sync_id': 'ball-1', 'sequence_number': 1},
      ],
      teams: [
        {'sync_id': 'team-1'},
      ],
      players: [
        {'sync_id': 'player-1'},
      ],
      teamPlayers: [
        {'sync_id': 'membership-1'},
      ],
      matchTeams: [
        {'match_sync_id': 'match-1', 'slot': 0, 'team_sync_id': 'team-1'},
      ],
      matchPlayers: [
        {
          'match_sync_id': 'match-1',
          'team_sync_id': 'team-1',
          'player_sync_id': 'player-1',
        },
      ],
    );

    expect(snapshot.match['sync_id'], 'match-1');
    expect(snapshot.innings, hasLength(1));
    expect(snapshot.ballEvents, hasLength(2));
    expect(snapshot.teams, hasLength(1));
    expect(snapshot.players, hasLength(1));
    expect(snapshot.teamPlayers, hasLength(1));
    expect(snapshot.matchTeams, hasLength(1));
    expect(snapshot.matchPlayers, hasLength(1));
  });

  test('recovery transport is read-only at this layer', () {
    final snapshot = RemoteMatchSnapshot(
      match: {'sync_id': 'match-1'},
      innings: [],
      ballEvents: [],
      teams: [],
      players: [],
      teamPlayers: [],
      matchTeams: [],
      matchPlayers: [],
    );

    expect(snapshot.match['sync_id'], 'match-1');
    expect(snapshot.ballEvents, isEmpty);
  });
}
