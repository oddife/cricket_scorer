import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../domain/innings/models/innings.dart';
import '../../domain/innings/models/innings_recalculation_context.dart';
import '../../domain/innings/models/innings_state.dart';
import '../../domain/innings/services/innings_recalculation_engine.dart';
import '../../domain/scoring/models/ball_event.dart';
import '../../domain/scoring/models/bowler_rotation_context.dart';
import '../../domain/scoring/models/bowler_rotation_result.dart';
import '../../domain/scoring/models/delivery_input.dart';
import '../../domain/scoring/models/scoring_context.dart';
import '../../domain/scoring/services/bowler_rotation_engine.dart';
import '../../domain/scoring/services/scoring_engine.dart';

class PersistedScoringActionResult {
  const PersistedScoringActionResult({
    required this.ballEventId,
    required this.state,
    required this.rotation,
  });

  final int ballEventId;
  final InningsState state;
  final BowlerRotationResult rotation;
}

class ApplyScoringActionService {
  const ApplyScoringActionService({
    required this.inningsRepository,
    required this.ballEventRepository,
    this.scoringEngine = const ScoringEngine(),
    this.bowlerRotationEngine = const BowlerRotationEngine(),
    this.recalculationEngine = const InningsRecalculationEngine(),
  });

  final InningsRepository inningsRepository;
  final BallEventRepository ballEventRepository;
  final ScoringEngine scoringEngine;
  final BowlerRotationEngine bowlerRotationEngine;
  final InningsRecalculationEngine recalculationEngine;

  Future<PersistedScoringActionResult> apply({
    required int inningsId,
    required DeliveryInput input,
    required int bowlerId,
    required List<int> eligibleBowlerIds,
    List<int> activeTwoBowlerIds = const <int>[],
  }) async {
    final innings = await inningsRepository.getById(inningsId);
    if (innings == null) {
      throw StateError('Innings $inningsId was not found.');
    }

    var balls = await ballEventRepository.getForInnings(inningsId);
    final currentState = _recalculate(innings, balls);

    if (currentState.inningsComplete) {
      throw StateError('Innings $inningsId is already complete.');
    }
    if (currentState.requiresBatterReplacement) {
      throw StateError('A replacement batter is required before scoring.');
    }

    _validateBowlerSelection(
      innings: innings,
      balls: balls,
      bowlerId: bowlerId,
      eligibleBowlerIds: eligibleBowlerIds,
      activeTwoBowlerIds: activeTwoBowlerIds,
      legalBallsInCurrentOver: currentState.legalBallsInCurrentOver,
    );

    final event = scoringEngine.score(
      context: ScoringContext(
        inningsId: inningsId,
        sequenceNumber: balls.length + 1,
        overNumber: currentState.completedOvers + 1,
        legalBallsInCurrentOver: currentState.legalBallsInCurrentOver,
        ballsPerOver: innings.ballsPerOver,
        bowlerId: bowlerId,
        strikerId: currentState.strikerId,
        nonStrikerId: currentState.nonStrikerId,
        timestamp: DateTime.now(),
      ),
      input: input,
    );

    final rotation = bowlerRotationEngine.apply(
      BowlerRotationContext(
        eligibleBowlerIds: eligibleBowlerIds,
        currentBowlerId: bowlerId,
        legalBallsInCurrentOver: currentState.legalBallsInCurrentOver,
        ballsPerOver: innings.ballsPerOver,
        twoBowlerMode: innings.twoBowlerMode,
        completedOvers: currentState.completedOvers,
        isLegalBall: event.isLegalBall,
        activeTwoBowlerIds: innings.twoBowlerMode
            ? activeTwoBowlerIds
            : const <int>[],
        totalOvers: innings.oversPerInnings,
        isFinalOver: currentState.completedOvers + 1 == innings.oversPerInnings,
      ),
    );

    final persisted = await ballEventRepository.create(event);
    balls = await ballEventRepository.getForInnings(inningsId);

    return PersistedScoringActionResult(
      ballEventId: persisted.id,
      state: _recalculate(innings, balls),
      rotation: rotation,
    );
  }

  void _validateBowlerSelection({
    required Innings innings,
    required List<BallEvent> balls,
    required int bowlerId,
    required List<int> eligibleBowlerIds,
    required List<int> activeTwoBowlerIds,
    required int legalBallsInCurrentOver,
  }) {
    if (eligibleBowlerIds.isEmpty) {
      throw ArgumentError('At least one eligible bowler is required.');
    }
    if (!eligibleBowlerIds.contains(bowlerId)) {
      throw ArgumentError('Selected bowler must be in the bowling XI.');
    }

    if (!innings.twoBowlerMode) {
      if (legalBallsInCurrentOver > 0) {
        final currentOverBowlers = _bowlersInOver(
          balls,
          balls.isEmpty ? 0 : balls.map((ball) => ball.overNumber).reduce((a, b) => a > b ? a : b),
        );
        if (currentOverBowlers.length == 1 &&
            currentOverBowlers.first != bowlerId) {
          throw StateError('A bowler cannot change during an over.');
        }
      } else if (balls.isNotEmpty) {
        final previousOver = balls.map((ball) => ball.overNumber).reduce(
              (a, b) => a > b ? a : b,
            );
        final previousBowlers = _bowlersInOver(balls, previousOver);
        if (previousBowlers.length == 1 && previousBowlers.first == bowlerId) {
          throw StateError('A bowler cannot bowl consecutive overs.');
        }
      }
      return;
    }

    if (activeTwoBowlerIds.length != 2 ||
        activeTwoBowlerIds.toSet().length != 2) {
      throw ArgumentError(
        'Two-Bowler Mode requires exactly two active bowlers.',
      );
    }
    if (!activeTwoBowlerIds.contains(bowlerId)) {
      throw ArgumentError('Selected bowler must be in the active pair.');
    }
    for (final id in activeTwoBowlerIds) {
      if (!eligibleBowlerIds.contains(id)) {
        throw ArgumentError('Active bowlers must be in the bowling XI.');
      }
    }

    final currentOver = innings.oversPerInnings == 0
        ? 1
        : (balls.isEmpty ? 1 : balls.map((ball) => ball.overNumber).reduce((a, b) => a > b ? a : b));
    final completedOvers = currentOver - 1;

    if (completedOvers.isEven && completedOvers > 0 && legalBallsInCurrentOver == 0) {
      final previousBowlers = _bowlersInOver(balls, completedOvers);
      if (previousBowlers.any(activeTwoBowlerIds.contains)) {
        throw StateError(
          'An active two-bowler pair cannot include a bowler from the previous over.',
        );
      }
    }

    if (completedOvers.isOdd && legalBallsInCurrentOver == 0) {
      final previousBowlers = _bowlersInOver(balls, completedOvers);
      if (previousBowlers.length == 2 &&
          previousBowlers.toSet().difference(activeTwoBowlerIds.toSet()).isNotEmpty) {
        throw StateError(
          'The second over of a two-bowler block must use the same active pair.',
        );
      }
      if (previousBowlers.length == 2 &&
          bowlerId == previousBowlers.last) {
        // The rotation engine will select the other member to start the second
        // over; the scorer must not manually swap the pair order.
        throw StateError(
          'The second over of a two-bowler block must start with the other bowler.',
        );
      }
    }

    if (legalBallsInCurrentOver > 0) {
      final currentOverNumber = completedOvers + 1;
      final currentOverBowlers = _bowlersInOver(balls, currentOverNumber);
      if (currentOverBowlers.isNotEmpty) {
        final expected = activeTwoBowlerIds.first == currentOverBowlers.last
            ? activeTwoBowlerIds[1]
            : activeTwoBowlerIds[0];
        if (bowlerId != expected) {
          throw StateError('Two-Bowler Mode requires alternating bowlers.');
        }
      }
    }
  }

  List<int> _bowlersInOver(List<BallEvent> balls, int overNumber) {
    final result = <int>[];
    for (final ball in balls.where((ball) => ball.overNumber == overNumber)) {
      if (!result.contains(ball.bowlerId)) {
        result.add(ball.bowlerId);
      }
    }
    return result;
  }

  InningsState _recalculate(Innings innings, List<BallEvent> balls) {
    return recalculationEngine.recalculate(
      InningsRecalculationContext(
        balls: balls,
        initialStrikerId: innings.openingStrikerId,
        initialNonStrikerId: innings.openingNonStrikerId,
        initialBowlerId: innings.openingBowlerId,
        ballsPerOver: innings.ballsPerOver,
        totalOvers: innings.oversPerInnings,
      ),
    );
  }
}
