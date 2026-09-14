import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/enums/run_out_end.dart';
import 'package:cricket_scorer/domain/scoring/enums/wicket_type.dart';
import 'package:cricket_scorer/domain/scoring/models/delivery_input.dart';
import 'package:cricket_scorer/domain/scoring/models/wicket_input.dart';
import 'package:cricket_scorer/domain/scoring/services/scoring_engine.dart';
import 'package:cricket_scorer/domain/scoring/services/wicket_workflow_service.dart';

void main() {
  const wicketService = WicketWorkflowService();
  const scoringEngine = ScoringEngine();
  const fielders = <int>{30, 31};

  test('stumped on a wide remains one illegal delivery and credits bowler', () {
    final wicket = wicketService.create(
      input: const WicketInput(
        type: WicketType.stumped,
        dismissedPlayerId: 10,
        fielderId: 30,
        deliveryType: DeliveryType.wide,
      ),
      strikerId: 10,
      nonStrikerId: 11,
      eligibleFielderIds: fielders,
    );

    final event = scoringEngine.score(
      context: const _Context().value,
      input: DeliveryInput(
        deliveryType: DeliveryType.wide,
        wideRuns: 1,
        wicket: wicket,
      ),
    );

    expect(event.isLegalBall, isFalse);
    expect(event.legalBallNumber, 0);
    expect(event.totalRuns, 1);
    expect(event.wicket?.type, WicketType.stumped);
    expect(event.wicket?.creditedToBowler, isTrue);
  });

  test('run out on a no-ball keeps the no-ball penalty and no bowler wicket', () {
    final wicket = wicketService.create(
      input: const WicketInput(
        type: WicketType.runOut,
        dismissedPlayerId: 11,
        fielderId: 30,
        runOutEnd: RunOutEnd.nonStriker,
        completedRuns: 1,
        crossedBeforeWicket: false,
        deliveryType: DeliveryType.noBall,
      ),
      strikerId: 10,
      nonStrikerId: 11,
      eligibleFielderIds: fielders,
    );

    final event = scoringEngine.score(
      context: const _Context().value,
      input: DeliveryInput(
        deliveryType: DeliveryType.noBall,
        noBallRuns: 1,
        wicket: wicket,
      ),
    );

    expect(event.isLegalBall, isFalse);
    expect(event.totalRuns, 1);
    expect(event.wicket?.type, WicketType.runOut);
    expect(event.wicket?.creditedToBowler, isFalse);
  });
}

class _Context {
  const _Context();

  dynamic get value => const _ScoringContextValue();
}

class _ScoringContextValue {
  const _ScoringContextValue();
}
