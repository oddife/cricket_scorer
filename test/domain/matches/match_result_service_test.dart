import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/innings/enums/innings_status.dart';
import 'package:cricket_scorer/domain/innings/models/innings.dart';
import 'package:cricket_scorer/domain/innings/models/innings_state.dart';
import 'package:cricket_scorer/domain/matches/enums/match_status.dart';
import 'package:cricket_scorer/domain/matches/models/match.dart';
import 'package:cricket_scorer/domain/matches/services/match_result_service.dart';

void main() {
  const service = MatchResultService();

  Match match() => const Match(
        id: 1,
        name: 'Four Innings Test',
        date: DateTime(2026, 1, 1),
        inningsCount: 4,
        oversPerInnings: 20,
        ballsPerOver: 6,
        playersPerTeam: 11,
        twoBowlerMode: false,
        status: MatchStatus.live,
      );

  Innings inning(int number, int battingTeamId, {InningsStatus status = InningsStatus.live}) => Innings(
        id: number,
        matchId: 1,
        inningsNumber: number,
        battingTeamId: battingTeamId,
        bowlingTeamId: battingTeamId == 10 ? 20 : 10,
        openingStrikerId: 1,
        openingNonStrikerId: 2,
        openingBowlerId: 3,
        oversPerInnings: 20,
        ballsPerOver: 6,
        twoBowlerMode: false,
        status: status,
      );

  InningsState state(int score, {bool targetReached = false}) => InningsState(
        score: score,
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
        batters: const {},
        bowlers: const {},
        ballCount: 0,
        requiresBatterReplacement: false,
        targetReached: targetReached,
        oversComplete: false,
        wicketsComplete: false,
      );

  test('fourth innings target is calculated from both completed innings', () {
    final innings = [
      inning(1, 10),
      inning(2, 20),
      inning(3, 10),
    ];
    final states = {
      1: state(100),
      2: state(80),
      3: state(50),
    };

    final target = service.targetForInnings(
      match: match(),
      innings: innings,
      states: states,
      inningsNumber: 4,
    );

    expect(target, 71);
  });

  test('four-innings match stays incomplete while final innings is live', () {
    final innings = [
      inning(1, 10, status: InningsStatus.ended),
      inning(2, 20, status: InningsStatus.ended),
      inning(3, 10, status: InningsStatus.ended),
      inning(4, 20),
    ];
    final states = {
      1: state(100),
      2: state(80),
      3: state(50),
      4: state(60),
    };

    final result = service.result(
      match: match(),
      innings: innings,
      states: states,
    );

    expect(result.completed, isFalse);
  });

  test('four-innings match completes with wickets when final team reaches target', () {
    final innings = [
      inning(1, 10, status: InningsStatus.ended),
      inning(2, 20, status: InningsStatus.ended),
      inning(3, 10, status: InningsStatus.ended),
      inning(4, 20),
    ];
    final states = {
      1: state(100),
      2: state(80),
      3: state(50),
      4: state(71, targetReached: true),
    };

    final result = service.result(
      match: match(),
      innings: innings,
      states: states,
    );

    expect(result.completed, isTrue);
    expect(result.winnerTeamId, 20);
    expect(result.marginWickets, 10);
    expect(result.marginRuns, isNull);
  });

  test('four-innings match completes on final innings end with a runs margin', () {
    final innings = [
      inning(1, 10, status: InningsStatus.ended),
      inning(2, 20, status: InningsStatus.ended),
      inning(3, 10, status: InningsStatus.ended),
      inning(4, 20, status: InningsStatus.ended),
    ];
    final states = {
      1: state(100),
      2: state(80),
      3: state(50),
      4: state(60),
    };

    final result = service.result(
      match: match(),
      innings: innings,
      states: states,
    );

    expect(result.completed, isTrue);
    expect(result.winnerTeamId, 10);
    expect(result.marginRuns, 10);
    expect(result.marginWickets, isNull);
  });

  test('four-innings match can finish tied after final innings ends', () {
    final innings = [
      inning(1, 10, status: InningsStatus.ended),
      inning(2, 20, status: InningsStatus.ended),
      inning(3, 10, status: InningsStatus.ended),
      inning(4, 20, status: InningsStatus.ended),
    ];
    final states = {
      1: state(100),
      2: state(80),
      3: state(50),
      4: state(70),
    };

    final result = service.result(
      match: match(),
      innings: innings,
      states: states,
    );

    expect(result.completed, isTrue);
    expect(result.isTie, isTrue);
    expect(result.winnerTeamId, isNull);
  });
}
