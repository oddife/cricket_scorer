import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../domain/innings/models/innings.dart';
import '../../domain/innings/models/innings_recalculation_context.dart';
import '../../domain/innings/models/innings_state.dart';
import '../../domain/innings/services/innings_recalculation_engine.dart';
import '../../domain/scoring/enums/delivery_type.dart';
import '../../domain/scoring/models/ball_event.dart';
import '../../domain/scoring/models/bowler_rotation_context.dart';
import '../../domain/scoring/models/bowler_rotation_result.dart';
import '../../domain/scoring/models/delivery_input.dart';
import '../../domain/scoring/models/scoring_context.dart';
import '../../domain/scoring/services/bowler_rotation_engine.dart';
import '../../domain/scoring/services/scoring_engine.dart';

class PersistedScoringActionResult {
  const PersistedScoringActionResult({required this.ballEventId, required this.state, required this.rotation});
  final int ballEventId;
  final InningsState state;
  final BowlerRotationResult rotation;
}

class ApplyScoringActionService {
  const ApplyScoringActionService({required this.inningsRepository, required this.ballEventRepository, this.scoringEngine = const ScoringEngine(), this.bowlerRotationEngine = const BowlerRotationEngine(), this.recalculationEngine = const InningsRecalculationEngine()});
  final InningsRepository inningsRepository;
  final BallEventRepository ballEventRepository;
  final ScoringEngine scoringEngine;
  final BowlerRotationEngine bowlerRotationEngine;
  final InningsRecalculationEngine recalculationEngine;

  Future<PersistedScoringActionResult> apply({required int inningsId, required DeliveryInput input, required int bowlerId, required List<int> eligibleBowlerIds, List<int> activeTwoBowlerIds = const <int>[], int? strikerIdOverride, int? nonStrikerIdOverride}) async {
    final innings = await inningsRepository.getById(inningsId);
    if (innings == null) throw StateError('Innings $inningsId was not found.');
    var balls = await ballEventRepository.getForInnings(inningsId);
    final target = await targetForInnings(innings);
    final currentState = _recalculate(innings, balls, target: target);
    if (currentState.inningsComplete) throw StateError('Innings $inningsId is already complete.');
    if (currentState.requiresBatterReplacement) throw StateError('A replacement batter is required before scoring.');
    final strikerId = strikerIdOverride ?? currentState.strikerId;
    final nonStrikerId = nonStrikerIdOverride ?? currentState.nonStrikerId;
    if (strikerId <= 0 || nonStrikerId <= 0 || strikerId == nonStrikerId) throw ArgumentError('A valid striker and non-striker are required.');
    final isLegalDelivery = input.deliveryType != DeliveryType.wide && input.deliveryType != DeliveryType.noBall;
    final effectiveBowlerId = _effectiveBowlerId(
      innings: innings,
      balls: balls,
      bowlerId: bowlerId,
      activeTwoBowlerIds: activeTwoBowlerIds,
      state: currentState,
      isLegalDelivery: isLegalDelivery,
    );
    _validateBowlerSelection(innings: innings, balls: balls, bowlerId: effectiveBowlerId, eligibleBowlerIds: eligibleBowlerIds, activeTwoBowlerIds: activeTwoBowlerIds, state: currentState, isLegalDelivery: isLegalDelivery);
    final event = scoringEngine.score(context: ScoringContext(inningsId: inningsId, sequenceNumber: balls.length + 1, overNumber: currentState.completedOvers + 1, legalBallsInCurrentOver: currentState.legalBallsInCurrentOver, ballsPerOver: innings.ballsPerOver, bowlerId: effectiveBowlerId, strikerId: strikerId, nonStrikerId: nonStrikerId, timestamp: DateTime.now()), input: input);
    final finalOddOver = innings.twoBowlerMode && currentState.completedOvers + 1 == innings.oversPerInnings && (currentState.completedOvers + 1).isOdd;
    final rotation = bowlerRotationEngine.apply(BowlerRotationContext(eligibleBowlerIds: eligibleBowlerIds, currentBowlerId: effectiveBowlerId, legalBallsInCurrentOver: currentState.legalBallsInCurrentOver, ballsPerOver: innings.ballsPerOver, twoBowlerMode: innings.twoBowlerMode, completedOvers: currentState.completedOvers, isLegalBall: event.isLegalBall, activeTwoBowlerIds: innings.twoBowlerMode ? activeTwoBowlerIds : const <int>[], totalOvers: innings.oversPerInnings, isFinalOver: finalOddOver));
    final persisted = await ballEventRepository.create(event);
    balls = await ballEventRepository.getForInnings(inningsId);
    return PersistedScoringActionResult(ballEventId: persisted.id, state: _recalculate(innings, balls, target: target), rotation: rotation);
  }

  Future<int?> targetForInnings(Innings current) async {
    if (current.inningsNumber == 2) {
      final first = await inningsRepository.getByMatchAndNumber(current.matchId, 1);
      if (first == null) return null;
      return _recalculate(first, await ballEventRepository.getForInnings(first.id)).score + 1;
    }
    if (current.inningsNumber == 4) {
      final first = await inningsRepository.getByMatchAndNumber(current.matchId, 1);
      final second = await inningsRepository.getByMatchAndNumber(current.matchId, 2);
      final third = await inningsRepository.getByMatchAndNumber(current.matchId, 3);
      if (first == null || second == null || third == null || third.battingTeamId != first.battingTeamId) return null;
      final target = _recalculate(first, await ballEventRepository.getForInnings(first.id)).score + _recalculate(third, await ballEventRepository.getForInnings(third.id)).score - _recalculate(second, await ballEventRepository.getForInnings(second.id)).score + 1;
      return target < 1 ? 1 : target;
    }
    return null;
  }

  int _effectiveBowlerId({required Innings innings, required List<BallEvent> balls, required int bowlerId, required List<int> activeTwoBowlerIds, required InningsState state, required bool isLegalDelivery}) {
    if (!innings.twoBowlerMode || activeTwoBowlerIds.length != 2 || state.legalBallsInCurrentOver == 0) return bowlerId;
    final currentOverNumber = state.completedOvers + 1;
    final currentOverBowlers = _bowlersInOver(balls, currentOverNumber);
    if (currentOverBowlers.isEmpty) return bowlerId;
    final lastDelivery = balls.lastWhere((ball) => ball.overNumber == currentOverNumber);
    if (!lastDelivery.isLegalBall || !isLegalDelivery) return bowlerId;
    if (bowlerId != lastDelivery.bowlerId) return bowlerId;
    final alternate = activeTwoBowlerIds.first == lastDelivery.bowlerId
        ? activeTwoBowlerIds[1]
        : activeTwoBowlerIds[0];
    return alternate;
  }

  void _validateBowlerSelection({required Innings innings, required List<BallEvent> balls, required int bowlerId, required List<int> eligibleBowlerIds, required List<int> activeTwoBowlerIds, required InningsState state, required bool isLegalDelivery}) {
    if (eligibleBowlerIds.isEmpty) throw ArgumentError('At least one eligible bowler is required.');
    if (!eligibleBowlerIds.contains(bowlerId)) throw ArgumentError('Selected bowler must be in the bowling XI.');
    final currentOverNumber = state.completedOvers + 1;
    final currentOverBowlers = _bowlersInOver(balls, currentOverNumber);
    if (!innings.twoBowlerMode) {
      if (currentOverBowlers.isNotEmpty && currentOverBowlers.first != bowlerId) throw StateError('A bowler cannot change during an over.');
      if (state.legalBallsInCurrentOver == 0 && currentOverBowlers.isEmpty && state.completedOvers > 0) {
        final previous = _bowlersInOver(balls, state.completedOvers);
        if (previous.length == 1 && previous.first == bowlerId) throw StateError('A bowler cannot bowl consecutive overs.');
      }
      return;
    }
    final finalOddOver = innings.oversPerInnings > 0 && currentOverNumber == innings.oversPerInnings && innings.oversPerInnings.isOdd;
    if (finalOddOver) {
      if (activeTwoBowlerIds.length != 1 || activeTwoBowlerIds.first != bowlerId) throw ArgumentError('The final odd over requires exactly one selected bowler.');
      if (state.legalBallsInCurrentOver == 0 && state.completedOvers > 0 && _bowlersInOver(balls, state.completedOvers).contains(bowlerId)) throw StateError('A bowler cannot bowl consecutive overs.');
      return;
    }
    if (activeTwoBowlerIds.length != 2 || activeTwoBowlerIds.toSet().length != 2) throw ArgumentError('Two-Bowler Mode requires exactly two active bowlers.');
    if (!activeTwoBowlerIds.contains(bowlerId)) throw ArgumentError('Selected bowler must be in the active pair.');
    for (final id in activeTwoBowlerIds) {
      if (!eligibleBowlerIds.contains(id)) throw ArgumentError('Active bowlers must be in the bowling XI.');
    }
    if (state.legalBallsInCurrentOver == 0) {
      if (state.completedOvers.isOdd) {
        final previous = _bowlersInOver(balls, state.completedOvers);
        if (previous.length == 2 && previous.toSet().difference(activeTwoBowlerIds.toSet()).isNotEmpty) throw StateError('The second over of a two-bowler block must use the same active pair.');
      } else if (state.completedOvers > 0) {
        final previous = _bowlersInOver(balls, state.completedOvers);
        if (previous.any(activeTwoBowlerIds.contains)) throw StateError('An active two-bowler pair cannot include a bowler from the previous over.');
      }
      return;
    }
    if (currentOverBowlers.isEmpty) throw StateError('Unable to determine the current bowler rotation.');
    final lastDelivery = balls.lastWhere((ball) => ball.overNumber == currentOverNumber);
    final expectedBowler = lastDelivery.isLegalBall ? (activeTwoBowlerIds.first == lastDelivery.bowlerId ? activeTwoBowlerIds[1] : activeTwoBowlerIds[0]) : lastDelivery.bowlerId;
    if (bowlerId != expectedBowler) throw StateError(isLegalDelivery ? 'Two-Bowler Mode requires alternating bowlers.' : 'Illegal delivery must remain with the current bowler.');
  }

  List<int> _bowlersInOver(List<BallEvent> balls, int overNumber) {
    final result = <int>[];
    for (final ball in balls.where((ball) => ball.overNumber == overNumber)) {
      if (!result.contains(ball.bowlerId)) result.add(ball.bowlerId);
    }
    return result;
  }

  InningsState _recalculate(Innings innings, List<BallEvent> balls, {int? target}) => recalculationEngine.recalculate(InningsRecalculationContext(balls: balls, initialStrikerId: innings.openingStrikerId, initialNonStrikerId: innings.openingNonStrikerId, initialBowlerId: innings.openingBowlerId, ballsPerOver: innings.ballsPerOver, totalOvers: innings.oversPerInnings, target: target));
}
