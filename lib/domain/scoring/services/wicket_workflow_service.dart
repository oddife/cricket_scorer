import '../enums/delivery_type.dart';
import '../enums/wicket_type.dart';
import '../models/run_out_resolution.dart';
import '../models/wicket.dart';
import '../models/wicket_input.dart';

/// Validates scorer-entered wicket details and converts them into the
/// law-driven wicket model used by the scoring engine.
class WicketWorkflowService {
  const WicketWorkflowService();

  Wicket create({
    required WicketInput input,
    required int strikerId,
    required int nonStrikerId,
    required DeliveryType deliveryType,
    required Set<int> eligibleFielderIds,
  }) {
    _validate(
      input: input,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      deliveryType: deliveryType,
      eligibleFielderIds: eligibleFielderIds,
    );

    return Wicket(
      type: input.type,
      dismissedPlayerId: input.dismissedPlayerId,
      fielderId: input.fielderId,
      runOutEnd: input.runOutEnd,
      creditedToBowler: switch (input.type) {
        WicketType.bowled ||
        WicketType.caught ||
        WicketType.lbw ||
        WicketType.stumped ||
        WicketType.hitWicket ||
        WicketType.overFence => true,
        WicketType.runOut ||
        WicketType.retired ||
        WicketType.obstructingField => false,
      },
    );
  }

  void _validate({
    required WicketInput input,
    required int strikerId,
    required int nonStrikerId,
    required DeliveryType deliveryType,
    required Set<int> eligibleFielderIds,
  }) {
    if (input.dismissedPlayerId <= 0) {
      throw ArgumentError.value(input.dismissedPlayerId, 'dismissedPlayerId');
    }
    if (strikerId <= 0 || nonStrikerId <= 0 || strikerId == nonStrikerId) {
      throw ArgumentError('A valid striker and non-striker are required.');
    }
    if (input.completedRuns < 0) {
      throw ArgumentError.value(input.completedRuns, 'completedRuns');
    }

    final dismissedIsBatter =
        input.dismissedPlayerId == strikerId || input.dismissedPlayerId == nonStrikerId;
    if (!dismissedIsBatter) {
      throw ArgumentError('The dismissed player must be the striker or non-striker.');
    }

    // Retirement is a separate match action, not a delivery dismissal.
    if (input.type == WicketType.retired) {
      throw ArgumentError('Retirement must be recorded as a separate match action.');
    }

    final strikerOnly = switch (input.type) {
      WicketType.bowled ||
      WicketType.caught ||
      WicketType.lbw ||
      WicketType.stumped ||
      WicketType.hitWicket ||
      WicketType.overFence => true,
      WicketType.runOut || WicketType.obstructingField || WicketType.retired => false,
    };
    if (strikerOnly && input.dismissedPlayerId != strikerId) {
      throw ArgumentError('This dismissal type can only dismiss the striker.');
    }

    final requiresFielder = switch (input.type) {
      WicketType.caught ||
      WicketType.runOut ||
      WicketType.stumped => true,
      _ => false,
    };
    if (requiresFielder) {
      final fielderId = input.fielderId;
      if (fielderId == null || !eligibleFielderIds.contains(fielderId)) {
        throw ArgumentError('A valid fielder must be selected.');
      }
    } else if (input.fielderId != null) {
      throw ArgumentError('This dismissal type does not use a fielder.');
    }

    if (input.type == WicketType.runOut) {
      final end = input.runOutEnd;
      if (end == null) {
        throw ArgumentError('Run out requires the end where the wicket was broken.');
      }

      final resolution = const RunOutResolver().resolve(
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        runOutEnd: end,
        completedRuns: input.completedRuns,
        crossedBeforeWicket: input.crossedBeforeWicket,
      );
      if (resolution.dismissedPlayerId != input.dismissedPlayerId) {
        throw ArgumentError(
          'Run-out end and crossing details do not match the dismissed batter.',
        );
      }
    } else if (input.runOutEnd != null) {
      throw ArgumentError('runOutEnd is only valid for a run out.');
    }

    if (input.type != WicketType.runOut && input.completedRuns != 0) {
      throw ArgumentError('Completed runs are only entered for a run out.');
    }

    if (input.crossedBeforeWicket && input.completedRuns == 0) {
      throw ArgumentError('Crossing can only be recorded when a run was completed.');
    }

    if (deliveryType == DeliveryType.noBall &&
        input.type != WicketType.runOut &&
        input.type != WicketType.obstructingField) {
      throw ArgumentError(
        'On a no-ball, only run out or obstructing the field can be recorded here.',
      );
    }

    if (deliveryType == DeliveryType.wide &&
        input.type != WicketType.stumped &&
        input.type != WicketType.runOut &&
        input.type != WicketType.hitWicket &&
        input.type != WicketType.obstructingField) {
      throw ArgumentError(
        'On a wide, only hit wicket, obstructing the field, run out or stumped can be recorded here.',
      );
    }
  }
}
