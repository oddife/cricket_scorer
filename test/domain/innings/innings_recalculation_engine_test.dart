import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_scorer/domain/innings/models/innings_recalculation_context.dart';
import 'package:cricket_scorer/domain/innings/services/innings_recalculation_engine.dart';
import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/enums/wicket_type.dart';
import 'package:cricket_scorer/domain/scoring/models/ball_event.dart';
import 'package:cricket_scorer/domain/scoring/models/wicket.dart';

void main() {
  const engine = InningsRecalculationEngine();

  BallEvent ball({
    required int sequence,
    required int striker,
    int? nonStriker,
    int bowler = 3,
    DeliveryType type = DeliveryType.normal,
    bool legal = true,
    int legalNumber = 1,
    int batterRuns = 0,
    int byeRuns = 0,
    int legByeRuns = 0,
    int wideRuns = 0,
    int noBallRuns = 0,
    int totalRuns = 0,
    Wicket? wicket,
  }) {
    final resolvedNonStriker = nonStriker ?? (striker == 1 ? 2 : 1);
    return BallEvent(
      id: sequence,
      inningsId: 1,
      sequenceNumber: sequence,
      overNumber: ((sequence - 1) ~/ 6) + 1,
      legalBallNumber: legalNumber,
      bowlerId: bowler,
      strikerId: striker,
      nonStrikerId: resolvedNonStriker,
      deliveryType: type,
      isLegalBall: legal,
      batterRuns: batterRuns,
      byeRuns: byeRuns,
      legByeRuns: legByeRuns,
      wideRuns: wideRuns,
      noBallRuns: noBallRuns,
      totalRuns: totalRuns,
      wicket: wicket,
      timestamp: DateTime(2026, 1, 1),
    );
  }

  InningsRecalculationContext context(
    List<BallEvent> balls, {
    int? totalOvers,
    int? maxWickets,
    int? target,
  }) {
    return InningsRecalculationContext(
      balls: balls,
      initialStrikerId: 1,
      initialNonStrikerId: 2,
      initialBowlerId: 3,
      ballsPerOver: 6,
      totalOvers: totalOvers,
      maxWickets: maxWickets,
      target: target,
    );
  }

  test('empty innings returns opening state', () {
    final state = engine.recalculate(context(const []));

    expect(state.score, 0);
    expect(state.wickets, 0);
    expect(state.legalBalls, 0);
    expect(state.strikerId, 1);
    expect(state.nonStrikerId, 2);
    expect(state.bowlerId, 3);
    expect(state.ballCount, 0);
  });

  test('recalculates score, batter runs and strike', () {
    final state = engine.recalculate(context([
      ball(sequence: 1, striker: 1, batterRuns: 1, totalRuns: 1),
      ball(sequence: 2, striker: 2, batterRuns: 4, totalRuns: 4, legalNumber: 2),
    ]));

    expect(state.score, 5);
    expect(state.legalBalls, 2);
    expect(state.strikerId, 2);
    expect(state.nonStrikerId, 1);
    expect(state.batters[1]!.runs, 1);
    expect(state.batters[1]!.balls, 1);
    expect(state.batters[2]!.runs, 4);
    expect(state.batters[2]!.fours, 1);
  });

  test('extras and bowler runs are recalculated correctly', () {
    final state = engine.recalculate(context([
      ball(sequence: 1, striker: 1, type: DeliveryType.wide, legal: false, wideRuns: 1, totalRuns: 1),
      ball(sequence: 2, striker: 1, type: DeliveryType.noBall, legal: false, noBallRuns: 1, batterRuns: 2, totalRuns: 3),
      ball(sequence: 3, striker: 1, type: DeliveryType.bye, byeRuns: 2, totalRuns: 2, legalNumber: 1),
      ball(sequence: 4, striker: 2, type: DeliveryType.legBye, legByeRuns: 1, totalRuns: 1, legalNumber: 2),
    ]));

    expect(state.score, 7);
    expect(state.wides, 1);
    expect(state.noBalls, 1);
    expect(state.byes, 2);
    expect(state.legByes, 1);
    expect(state.legalBalls, 2);
    expect(state.batters[1]!.runs, 2);
    expect(state.batters[1]!.balls, 1);
    expect(state.bowlers[3]!.runsConceded, 4);
  });

  test('six legal balls complete the over', () {
    final balls = List.generate(
      6,
      (index) => ball(
        sequence: index + 1,
        striker: index.isEven ? 1 : 2,
        legalNumber: index + 1,
      ),
    );

    final state = engine.recalculate(context(balls, totalOvers: 10));

    expect(state.legalBalls, 6);
    expect(state.completedOvers, 1);
    expect(state.legalBallsInCurrentOver, 0);
    expect(state.bowlerId, 0);
  });

  test('wicket is credited only when BallEvent says it is', () {
    final state = engine.recalculate(context([
      ball(sequence: 1, striker: 1, wicket: const Wicket(type: WicketType.bowled, dismissedPlayerId: 1, creditedToBowler: true)),
      ball(sequence: 2, striker: 4, nonStriker: 2, legalNumber: 2),
    ]));

    expect(state.wickets, 1);
    expect(state.batters[1]!.isOut, isTrue);
    expect(state.bowlers[3]!.wickets, 1);
    expect(state.strikerId, 4);
    expect(state.nonStrikerId, 2);
    expect(state.requiresBatterReplacement, isFalse);
  });

  test('last wicket leaves batter replacement pending', () {
    final state = engine.recalculate(context([
      ball(sequence: 1, striker: 1, wicket: const Wicket(type: WicketType.runOut, dismissedPlayerId: 1, creditedToBowler: false, runOutEnd: RunOutEnd.striker)),
    ]));

    expect(state.wickets, 1);
    expect(state.requiresBatterReplacement, isTrue);
    expect(state.bowlers[3]!.wickets, 0);
  });

  test('target, overs and wicket completion flags are derived', () {
    final state = engine.recalculate(context(
      List.generate(6, (index) => ball(sequence: index + 1, striker: 1, batterRuns: 1, totalRuns: 1, legalNumber: index + 1)),
      totalOvers: 1,
      maxWickets: 9,
      target: 6,
    ));

    expect(state.score, 6);
    expect(state.targetReached, isTrue);
    expect(state.oversComplete, isTrue);
    expect(state.wicketsComplete, isFalse);
    expect(state.inningsComplete, isTrue);
  });

  test('recalculation is independent of input order', () {
    final first = ball(sequence: 1, striker: 1, batterRuns: 2, totalRuns: 2);
    final second = ball(sequence: 2, striker: 1, batterRuns: 4, totalRuns: 4, legalNumber: 2);

    final state = engine.recalculate(context([second, first]));

    expect(state.score, 6);
    expect(state.batters[1]!.runs, 6);
    expect(state.batters[1]!.fours, 1);
  });
}
