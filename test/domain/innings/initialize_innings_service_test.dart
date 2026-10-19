import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/application/matches/initialize_innings_service.dart';
import 'package:cricket_scorer/domain/matches/enums/match_team_slot.dart';
import 'package:cricket_scorer/domain/matches/enums/toss_decision.dart';
import 'package:cricket_scorer/domain/matches/models/match.dart';
import 'package:cricket_scorer/domain/matches/models/match_player.dart';
import 'package:cricket_scorer/domain/matches/models/match_team.dart';

void main() {
  const service = InitializeInningsService();

  final teams = [
    const MatchTeam(id: 1, matchId: 1, teamId: 10, slot: MatchTeamSlot.teamA),
    const MatchTeam(id: 2, matchId: 1, teamId: 20, slot: MatchTeamSlot.teamB),
  ];

  final players = [
    const MatchPlayer(id: 1, matchId: 1, teamId: 10, playerId: 101, isPlaying: true),
    const MatchPlayer(id: 2, matchId: 1, teamId: 10, playerId: 102, isPlaying: true),
    const MatchPlayer(id: 3, matchId: 1, teamId: 20, playerId: 201, isPlaying: true),
    const MatchPlayer(id: 4, matchId: 1, teamId: 20, playerId: 202, isPlaying: true),
  ];

  Match match() => Match(
        id: 1,
        name: 'Test',
        date: DateTime(2026, 1, 1),
        inningsCount: 2,
        oversPerInnings: 3,
        ballsPerOver: 6,
        playersPerTeam: 2,
        twoBowlerMode: false,
        tossWinnerTeamId: 10,
        tossDecision: TossDecision.bat,
      );

  test('allows innings 2 in a 2-innings match and switches batting teams', () {
    final innings = service.prepare(
      match: match(),
      matchTeams: teams,
      matchPlayers: players,
      inningsNumber: 2,
      strikerId: 201,
      nonStrikerId: 202,
      firstBowlerId: 101,
    );

    expect(innings.inningsNumber, 2);
    expect(innings.battingTeamId, 20);
    expect(innings.bowlingTeamId, 10);
    expect(innings.openingStrikerId, 201);
    expect(innings.openingNonStrikerId, 202);
    expect(innings.openingBowlerId, 101);
  });

  test('still rejects innings outside the configured count', () {
    expect(
      () => service.prepare(
        match: match(),
        matchTeams: teams,
        matchPlayers: players,
        inningsNumber: 3,
        strikerId: 101,
        nonStrikerId: 102,
        firstBowlerId: 201,
      ),
      throwsArgumentError,
    );
  });
}
