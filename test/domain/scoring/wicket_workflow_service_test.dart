import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/enums/run_out_end.dart';
import 'package:cricket_scorer/domain/scoring/enums/wicket_type.dart';
import 'package:cricket_scorer/domain/scoring/models/wicket_input.dart';
import 'package:cricket_scorer/domain/scoring/services/wicket_workflow_service.dart';

void main() {
  const service = WicketWorkflowService();
  const fielders = <int>{30, 31};

  test('creates a bowled wicket with bowler credit', () {
    final wicket = service.create(
      input: const WicketInput(
        type: WicketType.bowled,
        dismissedPlayerId: 10,
      ),
      strikerId: 10,
      nonStrikerId: 11,
      deliveryType: DeliveryType.normal,
      eligibleFielderIds: fielders,
    );

    expect(wicket.type, WicketType.bowled);
    expect(wicket.creditedToBowler, isTrue);
    expect(wicket.fielderId, isNull);
  });

  test('caught requires a valid fielder', () {
    expect(
      () => service.create(
        input: const WicketInput(
          type: WicketType.caught,
          dismissedPlayerId: 10,
        ),
        strikerId: 10,
        nonStrikerId: 11,
        deliveryType: DeliveryType.normal,
        eligibleFielderIds: fielders,
      ),
      throwsArgumentError,
    );
  });

  test('run out requires end and fielder and does not credit bowler', () {
    final wicket = service.create(
      input: const WicketInput(
        type: WicketType.runOut,
        dismissedPlayerId: 11,
        fielderId: 30,
        runOutEnd: RunOutEnd.nonStriker,
        completedRuns: 1,
        crossedBeforeWicket: true,
      ),
      strikerId: 10,
      nonStrikerId: 11,
      deliveryType: DeliveryType.normal,
      eligibleFielderIds: fielders,
    );

    expect(wicket.creditedToBowler, isFalse);
    expect(wicket.runOutEnd, RunOutEnd.nonStriker);
  });

  test('dismissed player must be one of the two current batters', () {
    expect(
      () => service.create(
        input: const WicketInput(
          type: WicketType.bowled,
          dismissedPlayerId: 99,
        ),
        strikerId: 10,
        nonStrikerId: 11,
        deliveryType: DeliveryType.normal,
        eligibleFielderIds: fielders,
      ),
      throwsArgumentError,
    );
  });

  test('no-ball only allows run out or obstructing field', () {
    expect(
      () => service.create(
        input: const WicketInput(
          type: WicketType.caught,
          dismissedPlayerId: 10,
          fielderId: 30,
        ),
        strikerId: 10,
        nonStrikerId: 11,
        deliveryType: DeliveryType.noBall,
        eligibleFielderIds: fielders,
      ),
      throwsArgumentError,
    );
  });

  test('wide permits stumped', () {
    final wicket = service.create(
      input: const WicketInput(
        type: WicketType.stumped,
        dismissedPlayerId: 10,
        fielderId: 30,
      ),
      strikerId: 10,
      nonStrikerId: 11,
      deliveryType: DeliveryType.wide,
      eligibleFielderIds: fielders,
    );

    expect(wicket.type, WicketType.stumped);
    expect(wicket.creditedToBowler, isTrue);
  });

  test('completed runs cannot be entered for a non-run-out wicket', () {
    expect(
      () => service.create(
        input: const WicketInput(
          type: WicketType.bowled,
          dismissedPlayerId: 10,
          completedRuns: 1,
        ),
        strikerId: 10,
        nonStrikerId: 11,
        deliveryType: DeliveryType.normal,
        eligibleFielderIds: fielders,
      ),
      throwsArgumentError,
    );
  });
}
