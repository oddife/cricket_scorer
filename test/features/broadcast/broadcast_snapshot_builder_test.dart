import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/innings/models/innings.dart';
import 'package:cricket_scorer/domain/innings/models/innings_state.dart';
import 'package:cricket_scorer/domain/matches/enums/match_status.dart';
import 'package:cricket_scorer/domain/matches/enums/match_team_slot.dart';
import 'package:cricket_scorer/domain/matches/models/match.dart';
import 'package:cricket_scorer/domain/matches/models/match_player.dart';
import 'package:cricket_scorer/domain/matches/models/match_team.dart';
import 'package:cricket_scorer/domain/players/models/player.dart';
import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/models/ball_event.dart';
import 'package:cricket_scorer/domain/teams/models/team.dart';
import 'package:cricket_scorer/features/broadcast/application/broadcast_snapshot_builder.dart';

void main() {
  group('BroadcastSnapshotBuilder', () {
    test('maps existing live scoring values to a display snapshot', () {
      final now = DateTime(2026, 10, 20, 12);
      final match = Match(
        id: 7,
        name: 'Ashes Season 12',
        date: now,
        inningsCount: 2,
        oversPerInnings: 20,
        ballsPerOver: 6,
        playersPerTeam: 11,
        twoBowlerMode: false,
        status: MatchStatus.live,
      );
      final innings = Innings(
        id: 70,
        matchId: 7,
        inningsNumber: 1,
        battingTeamId: 10,
        bowlingTeamId: 20,
        openingStrikerId: 1,
        openingNonStrikerId: 2,
        openingBowlerId: 3,
        oversPerInnings: 20,
        ballsPerOver: 6,
        twoBowlerMode: false,
      );
      final score = InningsState(
        score: 6,
        wickets: 0,
        legalBalls: 1,
        ballsPerOver: 6,
        strikerId: 1,
        nonStrikerId: 2,
        bowlerId: 3,
        wides: 2,
        noBalls: 0,
        byes: 0,
        legByes: 0,
        batters: const {
          1: BatterInningsState(
            playerId: 1,
            runs: 4,
            balls: 1,
            fours: 1,
            sixes: 0,
            isOut: false,
          ),
          2: BatterInningsState(
            playerId: 2,
            runs: 0,
            balls: 0,
            fours: 0,
            sixes: 0,
            isOut: false,
          ),
        },
        bowlers: const {
          3: BowlerInningsState(
            playerId: 3,
            legalBalls: 1,
            runsConceded: 6,
            wickets: 0,
          ),
        },
        ballCount: 2,
        requiresBatterReplacement: false,
        targetReached: false,
        oversComplete: false,
        wicketsComplete: false,
      );
      final events = [
        BallEvent(
          id: 1,
          inningsId: 70,
          sequenceNumber: 1,
          overNumber: 1,
          legalBallNumber: 1,
          bowlerId: 3,
          strikerId: 1,
          nonStrikerId: 2,
          deliveryType: DeliveryType.normal,
          isLegalBall: true,
          batterRuns: 4,
          byeRuns: 0,
          legByeRuns: 0,
          wideRuns: 0,
          noBallRuns: 0,
          totalRuns: 4,
          timestamp: now,
        ),
        BallEvent(
          id: 2,
          inningsId: 70,
          sequenceNumber: 2,
          overNumber: 1,
          legalBallNumber: 1,
          bowlerId: 3,
          strikerId: 1,
          nonStrikerId: 2,
          deliveryType: DeliveryType.wide,
          isLegalBall: false,
          batterRuns: 0,
          byeRuns: 0,
          legByeRuns: 0,
          wideRuns: 2,
          noBallRuns: 0,
          totalRuns: 2,
          timestamp: now.add(const Duration(seconds: 1)),
        ),
      ];

      final snapshot = BroadcastSnapshotBuilder.build(
        match: match,
        innings: innings,
        score: score,
        strikerId: 1,
        nonStrikerId: 2,
        selectedBowlerId: 3,
        matchTeams: const [
          MatchTeam(id: 1, matchId: 7, teamId: 10, slot: MatchTeamSlot.teamA),
          MatchTeam(id: 2, matchId: 7, teamId: 20, slot: MatchTeamSlot.teamB),
        ],
        teams: const [
          Team(id: 10, name: 'Kings', shortName: 'KIN'),
          Team(id: 20, name: 'Warriors', shortName: 'WAR'),
        ],
        matchPlayers: const [
          MatchPlayer(id: 1, matchId: 7, teamId: 10, playerId: 1, isPlaying: true),
          MatchPlayer(id: 2, matchId: 7, teamId: 10, playerId: 2, isPlaying: true),
          MatchPlayer(id: 3, matchId: 7, teamId: 20, playerId: 3, isPlaying: true),
        ],
        players: const [
          Player(id: 1, name: 'Oddi', displayName: 'Oddi'),
          Player(id: 2, name: 'Dion', displayName: 'Dion'),
          Player(id: 3, name: 'Mario', displayName: 'Mario'),
        ],
        events: events,
        target: 12,
        capturedAt: now,
      );

      expect(snapshot.ready, isTrue);
      expect(snapshot.matchId, '7');
      expect(snapshot.matchName, 'Ashes Season 12');
      expect(snapshot.teamAName, 'Kings');
      expect(snapshot.teamBName, 'Warriors');
      expect(snapshot.battingTeamName, 'Kings');
      expect(snapshot.bowlingTeamName, 'Warriors');
      expect(snapshot.runs, 6);
      expect(snapshot.wickets, 0);
      expect(snapshot.oversText, '0.1');
      expect(snapshot.target, 12);
      expect(snapshot.runsRequired, 6);
      expect(snapshot.ballsRemaining, 119);
      expect(snapshot.batters.first.name, 'Oddi');
      expect(snapshot.batters.first.isOnStrike, isTrue);
      expect(snapshot.bowler?.name, 'Mario');
      expect(snapshot.currentOver.map((delivery) => delivery.label),
          ['4', 'Wd+1']);
      expect(snapshot.currentOver.last.isLegalBall, isFalse);
      expect(snapshot.currentOver.last.totalRuns, 2);
      expect(snapshot.capturedAt, now);
    });

    test('returns null rates before any legal delivery', () {
      final now = DateTime(2026, 10, 20);
      final snapshot = BroadcastSnapshotBuilder.build(
        match: Match(
          id: 1,
          name: 'Practice',
          date: now,
          inningsCount: 2,
          oversPerInnings: 5,
          ballsPerOver: 6,
          playersPerTeam: 6,
          twoBowlerMode: false,
          status: MatchStatus.live,
        ),
        innings: Innings(
          id: 2,
          matchId: 1,
          inningsNumber: 1,
          battingTeamId: 10,
          bowlingTeamId: 20,
          openingStrikerId: 1,
          openingNonStrikerId: 2,
          openingBowlerId: 3,
          oversPerInnings: 5,
          ballsPerOver: 6,
          twoBowlerMode: false,
        ),
        score: const InningsState(
          score: 0,
          wickets: 0,
          legalBalls: 0,
          ballsPerOver: 6,
          strikerId: 1,
          nonStrikerId: 2,
          bowlerId: 3,
          wides: 0,
          noBalls: 0,
          byes: 0,
          legByes: 0,
          batters: {},
          bowlers: {},
          ballCount: 0,
          requiresBatterReplacement: false,
          targetReached: false,
          oversComplete: false,
          wicketsComplete: false,
        ),
        strikerId: 1,
        nonStrikerId: 2,
        matchTeams: const [],
        teams: const [],
        matchPlayers: const [],
        players: const [],
        events: const [],
        target: 10,
        capturedAt: now,
      );

      expect(snapshot.runRate, isNull);
      expect(snapshot.requiredRunRate, closeTo(2.0, 0.0001));
      expect(snapshot.currentOver, isEmpty);
      expect(snapshot.recentDeliveries, isEmpty);
    });
  });
}
