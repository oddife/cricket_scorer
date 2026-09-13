import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
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
    final currentState = recalculationEngine.recalculate(
      InningsRecalculationContext(
        balls: balls,
        initialStrikerId: innings.openingStrikerId,
        initialNonStrikerId: innings.openingNonStrikerId,
        initialBowlerId: innings.openingBowlerId,
        ballsPerOver: innings.ballsPerOver,
        totalOvers: innings.oversPerInnings,
        maxWickets: _maxWickets(innings),
      ),
    );

    if (currentState.inningsComplete) {
      throw StateError('Innings $inningsId is already complete.');
    }
    if (currentState.requiresBatterReplacement) {
      throw StateError('A replacement batter is required before scoring.');
    }
    if (bowlerId <= 0) {
      throw ArgumentError.value(bowlerId, 'bowlerId');
    }

    final sequenceNumber = balls.length + 1;
    final overNumber = currentState.completedOvers + 1;
    final scoringContext = ScoringContext(
      inningsId: inningsId,
      sequenceNumber: sequenceNumber,
      overNumber: overNumber,
      legalBallsInCurrentOver: currentState.legalBallsInCurrentOver,
      ballsPerOver: innings.ballsPerOver,
      bowlerId: bowlerId,
      strikerId: currentState.strikerId,
      nonStrikerId: currentState.nonStrikerId,
      timestamp: DateTime.now(),
    );

    final event = scoringEngine.score(
      context: scoringContext,
      input: input,
    );

    final persisted = await ballEventRepository.create(event);
    balls = await ballEventRepository.getForInnings(inningsId);

    final state = recalculationEngine.recalculate(
      InningsRecalculationContext(
        balls: balls,
        initialStrikerId: innings.openingStrikerId,
        initialNonStrikerId: innings.openingNonStrikerId,
        initialBowlerId: innings.openingBowlerId,
        ballsPerOver: innings.ballsPerOver,
        totalOvers: innings.oversPerInnings,
        maxWickets: _maxWickets(innings),
      ),
    );

    return PersistedScoringActionResult(
      ballEventId: persisted.id,
      state: state,
    );
  }

  int? _maxWickets(dynamic innings) {
    // The current innings model does not persist players-per-team. Until
    // that match setting is exposed here, wicket completion is derived by
    // the application layer when the playing XI is available.
    return null;
  }
}
