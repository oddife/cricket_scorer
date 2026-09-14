import '../enums/delivery_type.dart';
import '../enums/wicket_type.dart';
import '../models/ball_event.dart';
import '../models/delivery_input.dart';
import '../models/scoring_context.dart';
import '../models/wicket.dart';

class ScoringEngine {
  const ScoringEngine();

  BallEvent score({
    required ScoringContext context,
    required DeliveryInput input,
  }) {
    _validate(context, input);

    final isLegalBall = switch (input.deliveryType) {
      DeliveryType.normal || DeliveryType.bye || DeliveryType.legBye => true,
      DeliveryType.wide || DeliveryType.noBall => false,
    };

    final legalBallNumber = isLegalBall
        ? context.legalBallsInCurrentOver + 1
        : context.legalBallsInCurrentOver;

    final wicket = input.wicket == null
        ? null
        : _withCorrectBowlerCredit(input.wicket!);

    final totalRuns = input.batterRuns +
        input.byeRuns +
        input.legByeRuns +
        input.wideRuns +
        input.noBallRuns;

    return BallEvent(
      id: 0,
      inningsId: context.inningsId,
      sequenceNumber: context.sequenceNumber,
      overNumber: context.overNumber,
      legalBallNumber: legalBallNumber,
      bowlerId: context.bowlerId,
      strikerId: context.strikerId,
      nonStrikerId: context.nonStrikerId,
      deliveryType: input.deliveryType,
      isLegalBall: isLegalBall,
      batterRuns: input.batterRuns,
      byeRuns: input.byeRuns,
      legByeRuns: input.legByeRuns,
      wideRuns: input.wideRuns,
      noBallRuns: input.noBallRuns,
      totalRuns: totalRuns,
      wicket: wicket,
      timestamp: context.timestamp,
    );
  }

  void _validate(ScoringContext context, DeliveryInput input) {
    if (context.inningsId <= 0) {
      throw ArgumentError.value(context.inningsId, 'inningsId');
    }
    if (context.sequenceNumber <= 0) {
      throw ArgumentError.value(context.sequenceNumber, 'sequenceNumber');
    }
    if (context.overNumber <= 0) {
      throw ArgumentError.value(context.overNumber, 'overNumber');
    }
    if (context.ballsPerOver <= 0) {
      throw ArgumentError.value(context.ballsPerOver, 'ballsPerOver');
    }
    if (context.legalBallsInCurrentOver < 0 ||
        context.legalBallsInCurrentOver >= context.ballsPerOver) {
      throw ArgumentError.value(
        context.legalBallsInCurrentOver,
        'legalBallsInCurrentOver',
      );
    }

    _validateNonNegative('batterRuns', input.batterRuns);
    _validateNonNegative('byeRuns', input.byeRuns);
    _validateNonNegative('legByeRuns', input.legByeRuns);
    _validateNonNegative('wideRuns', input.wideRuns);
    _validateNonNegative('noBallRuns', input.noBallRuns);

    switch (input.deliveryType) {
      case DeliveryType.normal:
        if (input.byeRuns != 0 ||
            input.legByeRuns != 0 ||
            input.wideRuns != 0 ||
            input.noBallRuns != 0) {
          throw ArgumentError('Normal delivery cannot contain extras.');
        }
      case DeliveryType.wide:
        if (input.wideRuns < 1 ||
            input.batterRuns != 0 ||
            input.byeRuns != 0 ||
            input.legByeRuns != 0 ||
            input.noBallRuns != 0) {
          throw ArgumentError('Wide must contain at least one wide run only.');
        }
      case DeliveryType.noBall:
        if (input.noBallRuns != 1 || input.wideRuns != 0) {
          throw ArgumentError('A no-ball must contain exactly one no-ball run.');
        }
        if (input.byeRuns != 0 && input.legByeRuns != 0) {
          throw ArgumentError('A no-ball cannot contain both bye and leg-bye runs.');
        }
      case DeliveryType.bye:
        if (input.byeRuns < 1 ||
            input.batterRuns != 0 ||
            input.legByeRuns != 0 ||
            input.wideRuns != 0 ||
            input.noBallRuns != 0) {
          throw ArgumentError('Bye must contain bye runs only.');
        }
      case DeliveryType.legBye:
        if (input.legByeRuns < 1 ||
            input.batterRuns != 0 ||
            input.byeRuns != 0 ||
            input.wideRuns != 0 ||
            input.noBallRuns != 0) {
          throw ArgumentError('Leg-bye must contain leg-bye runs only.');
        }
    }

    _validateWicket(input);

    if (input.deliveryType == DeliveryType.noBall && input.wicket != null) {
      final type = input.wicket!.type;
      if (type != WicketType.runOut && type != WicketType.obstructingField) {
        throw ArgumentError(
          'On a no-ball, only run out or obstructing the field can be recorded here.',
        );
      }
    }
  }

  void _validateWicket(DeliveryInput input) {
    final wicket = input.wicket;
    if (wicket == null) return;

    if (wicket.dismissedPlayerId <= 0) {
      throw ArgumentError.value(wicket.dismissedPlayerId, 'dismissedPlayerId');
    }
    if (wicket.type == WicketType.runOut && wicket.runOutEnd == null) {
      throw ArgumentError('Run out requires runOutEnd.');
    }
    if (wicket.type != WicketType.runOut && wicket.runOutEnd != null) {
      throw ArgumentError('runOutEnd is only valid for a run out.');
    }
    if (wicket.type != WicketType.runOut && wicket.completedRuns != 0) {
      throw ArgumentError('Completed runs are only valid for a run out.');
    }
    if (wicket.type != WicketType.runOut && wicket.crossedBeforeWicket) {
      throw ArgumentError('Crossing is only valid for a run out.');
    }
  }

  Wicket _withCorrectBowlerCredit(Wicket wicket) {
    final credited = switch (wicket.type) {
      WicketType.bowled ||
      WicketType.caught ||
      WicketType.lbw ||
      WicketType.stumped ||
      WicketType.hitWicket ||
      WicketType.overFence => true,
      WicketType.runOut ||
      WicketType.retired ||
      WicketType.obstructingField => false,
    };

    return Wicket(
      type: wicket.type,
      dismissedPlayerId: wicket.dismissedPlayerId,
      fielderId: wicket.fielderId,
      runOutEnd: wicket.runOutEnd,
      completedRuns: wicket.completedRuns,
      crossedBeforeWicket: wicket.crossedBeforeWicket,
      replacementBatterId: wicket.replacementBatterId,
      creditedToBowler: credited,
    );
  }

  void _validateNonNegative(String name, int value) {
    if (value < 0) {
      throw ArgumentError.value(value, name);
    }
  }
}
