import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/enums/run_out_end.dart';
import 'package:cricket_scorer/domain/scoring/enums/wicket_type.dart';
import 'package:cricket_scorer/domain/scoring/models/delivery_input.dart';
import 'package:cricket_scorer/domain/scoring/models/scoring_context.dart';
import 'package:cricket_scorer/domain/scoring/models/wicket.dart';
import 'package:cricket_scorer/domain/scoring/services/scoring_engine.dart';

ScoringContext context({
  int legalBalls = 0,
}) {
  return ScoringContext(
    inningsId: 1,
    sequenceNumber: legalBalls + 1,
    overNumber: 1,
    legalBallsInCurrentOver: legalBalls,
    ballsPerOver: 6,
    bowlerId: 10,
    strikerId: 20,
    nonStrikerId: 21,
    timestamp: DateTime(2026, 1, 1),
  );
}

void main() {
  const engine = ScoringEngine();

  test('normal delivery is legal and records batter runs', () {
    final event = engine.score(
      context: context(legalBalls: 2),
      input: const DeliveryInput(
        deliveryType: DeliveryType.normal,
        batterRuns: 4,
      ),
    );

    expect(event.isLegalBall, isTrue);
    expect(event.legalBallNumber, 3);
    expect(event.batterRuns, 4);
    expect(event.totalRuns, 4);
  });

  test('wide is illegal and all selected wide runs go to bowler extras', () {
    final event = engine.score(
      context: context(),
      input: const DeliveryInput(
        deliveryType: DeliveryType.wide,
        wideRuns: 3,
      ),
    );

    expect(event.isLegalBall, isFalse);
    expect(event.legalBallNumber, 0);
    expect(event.batterRuns, 0);
    expect(event.wideRuns, 3);
    expect(event.totalRuns, 3);
  });

  test('no-ball with four batter runs records five team runs', () {
    final event = engine.score(
      context: context(legalBalls: 4),
      input: const DeliveryInput(
        deliveryType: DeliveryType.noBall,
        batterRuns: 4,
        noBallRuns: 1,
      ),
    );

    expect(event.isLegalBall, isFalse);
    expect(event.legalBallNumber, 4);
    expect(event.batterRuns, 4);
    expect(event.noBallRuns, 1);
    expect(event.totalRuns, 5);
  });

  test('bye is legal and does not credit the batter', () {
    final event = engine.score(
      context: context(),
      input: const DeliveryInput(
        deliveryType: DeliveryType.bye,
        byeRuns: 2,
      ),
    );

    expect(event.isLegalBall, isTrue);
    expect(event.legalBallNumber, 1);
    expect(event.batterRuns, 0);
    expect(event.byeRuns, 2);
    expect(event.totalRuns, 2);
  });

  test('run out is not credited to the bowler regardless of supplied flag', () {
    final event = engine.score(
      context: context(),
      input: DeliveryInput(
        deliveryType: DeliveryType.normal,
        wicket: const Wicket(
          type: WicketType.runOut,
          dismissedPlayerId: 20,
          runOutEnd: RunOutEnd.striker,
          creditedToBowler: true,
        ),
      ),
    );

    expect(event.hasWicket, isTrue);
    expect(event.wicket!.creditedToBowler, isFalse);
    expect(event.wicket!.runOutEnd, RunOutEnd.striker);
  });

  test('no-ball rejects a bowled wicket', () {
    expect(
      () => engine.score(
        context: context(),
        input: DeliveryInput(
          deliveryType: DeliveryType.noBall,
          noBallRuns: 1,
          wicket: const Wicket(
            type: WicketType.bowled,
            dismissedPlayerId: 20,
            creditedToBowler: true,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });
}
