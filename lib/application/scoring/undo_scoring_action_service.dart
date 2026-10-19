import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../domain/innings/models/innings_recalculation_context.dart';
import '../../domain/innings/models/innings_state.dart';
import '../../domain/innings/services/innings_recalculation_engine.dart';

class UndoScoringActionService {
  const UndoScoringActionService({
    required this.inningsRepository,
    required this.ballEventRepository,
    this.recalculationEngine = const InningsRecalculationEngine(),
  });

  final InningsRepository inningsRepository;
  final BallEventRepository ballEventRepository;
  final InningsRecalculationEngine recalculationEngine;

  Future<InningsState> undo({required int inningsId}) async {
    final innings = await inningsRepository.getById(inningsId);
    if (innings == null) {
      throw StateError('Innings $inningsId was not found.');
    }

    final balls = await ballEventRepository.getForInnings(inningsId);
    if (balls.isEmpty) {
      throw StateError('There are no scoring actions to undo.');
    }

    final lastBall = balls.reduce(
      (a, b) => a.sequenceNumber > b.sequenceNumber ? a : b,
    );

    await ballEventRepository.deleteById(lastBall.id);
    final remainingBalls = await ballEventRepository.getForInnings(inningsId);

    return recalculationEngine.recalculate(
      InningsRecalculationContext(
        balls: remainingBalls,
        initialStrikerId: innings.openingStrikerId,
        initialNonStrikerId: innings.openingNonStrikerId,
        initialBowlerId: innings.openingBowlerId,
        ballsPerOver: innings.ballsPerOver,
        totalOvers: innings.oversPerInnings,
      ),
    );
  }
}
