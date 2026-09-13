import '../../scoring/models/ball_event.dart';
import 'innings_state.dart';

class ScoringActionResult {
  const ScoringActionResult({
    required this.ballEvent,
    required this.state,
  });

  final BallEvent ballEvent;
  final InningsState state;
}
