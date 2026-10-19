import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_scorer/domain/innings/services/apply_scoring_action_service.dart';
import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/models/delivery_input.dart';
import 'package:cricket_scorer/domain/scoring/models/scoring_context.dart';

void main() {
  const service = ApplyScoringActionService();

  test('creates a BallEvent and recalculates the new state', () {
    final result = service.apply(
      scoringContext: ScoringContext(
        inningsId: 1,
        sequenceNumber: 1,
        overNumber: 1,
        legalBallsInCurrentOver: 0,
        ballsPerOver: 6,
        bowlerId: 3,
        strikerId: 1,
        nonStrikerId: 2,
        timestamp: DateTime(2026, 1, 1),
      ),
      input: const DeliveryInput(
        deliveryType: DeliveryType.normal,
        batterRuns: 4,
      ),
      existingBalls: const [],
      initialStrikerId: 1,
      initialNonStrikerId: 2,
      initialBowlerId: 3,
      ballsPerOver: 6,
    );

    expect(result.ballEvent.totalRuns, 4);
    expect(result.ballEvent.isLegalBall, isTrue);
    expect(result.state.score, 4);
    expect(result.state.legalBalls, 1);
  });

  test('keeps illegal delivery out of the legal-ball count', () {
    final result = service.apply(
      scoringContext: ScoringContext(
        inningsId: 1,
        sequenceNumber: 1,
        overNumber: 1,
        legalBallsInCurrentOver: 0,
        ballsPerOver: 6,
        bowlerId: 3,
        strikerId: 1,
        nonStrikerId: 2,
        timestamp: DateTime(2026, 1, 1),
      ),
      input: const DeliveryInput(
        deliveryType: DeliveryType.wide,
        wideRuns: 1,
      ),
      existingBalls: const [],
      initialStrikerId: 1,
      initialNonStrikerId: 2,
      initialBowlerId: 3,
      ballsPerOver: 6,
    );

    expect(result.ballEvent.isLegalBall, isFalse);
    expect(result.state.score, 1);
    expect(result.state.legalBalls, 0);
  });
}
