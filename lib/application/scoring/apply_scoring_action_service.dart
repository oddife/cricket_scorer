import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../domain/innings/models/innings.dart';
import '../../domain/innings/models/innings_recalculation_context.dart';
import '../../domain/innings/models/innings_state.dart';
import '../../domain/innings/services/innings_recalculation_engine.dart';
import '../../domain/scoring/models/delivery_input.dart';
import '../../domain/scoring/models/scoring_context.dart';
import '../../domain/scoring/services/scoring_engine.dart';

class PersistedScoringActionResult {
  const PersistedScoringActionResult({
    required this.ballEventId,
    required this.state,
  });

  final int ballEventId;
  final InningsState state;
}

class ApplyScoringActionService {
  const ApplyScoringActionService({
    required this.inningsRepository,
    required this.ballEventRepository,
    this.scoringEngine = const ScoringEngine(),
    this.recalculationEngine = const InningsRecalculationEngine(),
  });

  final InningsRepository inningsRepository;
  final BallEventRepository ballEventRepository;
  final ScoringEngine scoringEngine;
  final InningsRecalculationEngine recalculationEngine;

  Future<PersistedScoringActionResult> apply({
    required int inningsId,
    required DeliveryInput input,
    required int bowlerId,
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
    if (bowlerId <= 0) {
      throw ArgumentError.value(bowlerId, 'bowlerId');
    }

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

    final persisted = await ballEventRepository.create(event);
    balls = await ballEventRepository.getForInnings(inningsId);

    return PersistedScoringActionResult(
      ballEventId: persisted.id,
      state: _recalculate(innings, balls),
    );
  }

  InningsState _recalculate(Innings innings, List<dynamic> balls) {
    return recalculationEngine.recalculate(
      InningsRecalculationContext(
        balls: balls.cast(),
        initialStrikerId: innings.openingStrikerId,
        initialNonStrikerId: innings.openingNonStrikerId,
        initialBowlerId: innings.openingBowlerId,
        ballsPerOver: innings.ballsPerOver,
        totalOvers: innings.oversPerInnings,
      ),
    );
  }
}
