import '../../scoring/models/delivery_input.dart';
import '../../scoring/models/scoring_context.dart';
import '../../scoring/services/scoring_engine.dart';
import '../models/innings_recalculation_context.dart';
import '../models/scoring_action_result.dart';
import 'innings_recalculation_engine.dart';

class ApplyScoringActionService {
  const ApplyScoringActionService({
    this.scoringEngine = const ScoringEngine(),
    this.recalculationEngine = const InningsRecalculationEngine(),
  });

  final ScoringEngine scoringEngine;
  final InningsRecalculationEngine recalculationEngine;

  ScoringActionResult apply({
    required ScoringContext scoringContext,
    required DeliveryInput input,
    required List<dynamic> existingBalls,
    required int initialStrikerId,
    required int initialNonStrikerId,
    required int initialBowlerId,
    required int ballsPerOver,
    int? totalOvers,
    int? maxWickets,
    int? target,
  }) {
    final ball = scoringEngine.score(
      context: scoringContext,
      input: input,
    );

    final balls = <dynamic>[...existingBalls, ball];

    final state = recalculationEngine.recalculate(
      InningsRecalculationContext(
        balls: balls.cast(),
        initialStrikerId: initialStrikerId,
        initialNonStrikerId: initialNonStrikerId,
        initialBowlerId: initialBowlerId,
        ballsPerOver: ballsPerOver,
        totalOvers: totalOvers,
        maxWickets: maxWickets,
        target: target,
      ),
    );

    return ScoringActionResult(ballEvent: ball, state: state);
  }
}
