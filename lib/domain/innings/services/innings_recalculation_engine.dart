import '../../scoring/enums/delivery_type.dart';
import '../../scoring/models/ball_event.dart';
import '../../scoring/models/strike_context.dart';
import '../../scoring/services/strike_engine.dart';
import '../models/innings_recalculation_context.dart';
import '../models/innings_state.dart';

class InningsRecalculationEngine {
  const InningsRecalculationEngine({this.strikeEngine = const StrikeEngine()});

  final StrikeEngine strikeEngine;

  InningsState recalculate(InningsRecalculationContext context) {
    _validate(context);

    final balls = [...context.balls]
      ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));

    var score = 0;
    var wickets = 0;
    var legalBalls = 0;
    var wides = 0;
    var noBalls = 0;
    var byes = 0;
    var legByes = 0;
    var strikerId = context.initialStrikerId;
    var nonStrikerId = context.initialNonStrikerId;
    var bowlerId = context.initialBowlerId;
    var requiresBatterReplacement = false;

    final batterRuns = <int, int>{};
    final batterBalls = <int, int>{};
    final batterFours = <int, int>{};
    final batterSixes = <int, int>{};
    final batterOut = <int>{};

    final bowlerLegalBalls = <int, int>{};
    final bowlerRuns = <int, int>{};
    final bowlerWickets = <int, int>{};

    for (var index = 0; index < balls.length; index++) {
      final ball = balls[index];

      if (ball.inningsId <= 0 || ball.sequenceNumber <= 0) {
        throw ArgumentError('Ball event contains an invalid identity.');
      }

      score += ball.totalRuns;
      wides += ball.wideRuns;
      noBalls += ball.noBallRuns;
      byes += ball.byeRuns;
      legByes += ball.legByeRuns;

      if (ball.wicket != null) {
        wickets++;
        batterOut.add(ball.wicket!.dismissedPlayerId);
      }

      batterRuns.update(
        ball.strikerId,
        (value) => value + ball.batterRuns,
        ifAbsent: () => ball.batterRuns,
      );

      if (ball.batterRuns == 4) {
        batterFours.update(ball.strikerId, (value) => value + 1, ifAbsent: () => 1);
      }
      if (ball.batterRuns == 6) {
        batterSixes.update(ball.strikerId, (value) => value + 1, ifAbsent: () => 1);
      }

      if (ball.isLegalBall) {
        legalBalls++;
        batterBalls.update(
          ball.strikerId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      bowlerLegalBalls.update(
        ball.bowlerId,
        (value) => value + (ball.isLegalBall ? 1 : 0),
        ifAbsent: () => ball.isLegalBall ? 1 : 0,
      );

      final bowlerConceded = ball.totalRuns - ball.byeRuns - ball.legByeRuns;
      bowlerRuns.update(
        ball.bowlerId,
        (value) => value + bowlerConceded,
        ifAbsent: () => bowlerConceded,
      );

      if (ball.wicket?.creditedToBowler == true) {
        bowlerWickets.update(
          ball.bowlerId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      final isEndOfOver = ball.isLegalBall &&
          ball.legalBallNumber == context.ballsPerOver;
      final completedRuns = _completedRuns(ball);

      final strikeResult = strikeEngine.apply(
        StrikeContext(
          strikerId: ball.strikerId,
          nonStrikerId: ball.nonStrikerId,
          completedRuns: completedRuns,
          isLegalBall: ball.isLegalBall,
          isEndOfOver: isEndOfOver,
        ),
      );

      strikerId = strikeResult.strikerId;
      nonStrikerId = strikeResult.nonStrikerId;
      bowlerId = ball.bowlerId;

      if (index + 1 < balls.length) {
        // The next BallEvent records the actual batter positions used for the
        // next delivery. This is also how a replacement batter after a wicket
        // is represented without duplicating mutable state in the database.
        final next = balls[index + 1];
        strikerId = next.strikerId;
        nonStrikerId = next.nonStrikerId;
        bowlerId = next.bowlerId;
        requiresBatterReplacement = false;
      } else {
        requiresBatterReplacement = ball.wicket != null;
      }
    }

    final completedOvers = legalBalls ~/ context.ballsPerOver;
    final legalBallsInCurrentOver = legalBalls % context.ballsPerOver;
    final overComplete = balls.isNotEmpty && legalBallsInCurrentOver == 0;
    final targetReached = context.target != null && score >= context.target!;
    final oversComplete = context.totalOvers != null &&
        legalBalls >= context.totalOvers! * context.ballsPerOver;
    final wicketsComplete = context.maxWickets != null &&
        wickets >= context.maxWickets!;

    final currentBowlerId = overComplete && balls.isNotEmpty ? 0 : bowlerId;

    return InningsState(
      score: score,
      wickets: wickets,
      legalBalls: legalBalls,
      ballsPerOver: context.ballsPerOver,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: currentBowlerId,
      wides: wides,
      noBalls: noBalls,
      byes: byes,
      legByes: legByes,
      batters: {
        for (final id in {...batterRuns.keys, ...batterBalls.keys, ...batterOut})
          id: BatterInningsState(
            playerId: id,
            runs: batterRuns[id] ?? 0,
            balls: batterBalls[id] ?? 0,
            fours: batterFours[id] ?? 0,
            sixes: batterSixes[id] ?? 0,
            isOut: batterOut.contains(id),
          ),
      },
      bowlers: {
        for (final id in bowlerLegalBalls.keys)
          id: BowlerInningsState(
            playerId: id,
            legalBalls: bowlerLegalBalls[id] ?? 0,
            runsConceded: bowlerRuns[id] ?? 0,
            wickets: bowlerWickets[id] ?? 0,
          ),
      },
      ballCount: balls.length,
    );
  }

  int _completedRuns(BallEvent ball) {
    return switch (ball.deliveryType) {
      DeliveryType.wide => ball.totalRuns - ball.wideRuns.clamp(1, ball.wideRuns),
      DeliveryType.noBall => ball.totalRuns - ball.noBallRuns,
      DeliveryType.normal || DeliveryType.bye || DeliveryType.legBye =>
        ball.totalRuns,
    };
  }

  void _validate(InningsRecalculationContext context) {
    if (context.initialStrikerId <= 0 || context.initialNonStrikerId <= 0) {
      throw ArgumentError('Opening batters must be valid player IDs.');
    }
    if (context.initialStrikerId == context.initialNonStrikerId) {
      throw ArgumentError('Opening batters must be different players.');
    }
    if (context.initialBowlerId <= 0) {
      throw ArgumentError.value(context.initialBowlerId, 'initialBowlerId');
    }
    if (context.ballsPerOver <= 0) {
      throw ArgumentError.value(context.ballsPerOver, 'ballsPerOver');
    }
    if (context.totalOvers != null && context.totalOvers! <= 0) {
      throw ArgumentError.value(context.totalOvers, 'totalOvers');
    }
    if (context.maxWickets != null && context.maxWickets! <= 0) {
      throw ArgumentError.value(context.maxWickets, 'maxWickets');
    }
    if (context.target != null && context.target! <= 0) {
      throw ArgumentError.value(context.target, 'target');
    }
  }
}
