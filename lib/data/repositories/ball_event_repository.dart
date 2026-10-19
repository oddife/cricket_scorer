import '../../domain/scoring/models/ball_event.dart';

abstract interface class BallEventRepository {
  Future<BallEvent> create(BallEvent event);
  Future<List<BallEvent>> getForInnings(int inningsId);
  Future<BallEvent?> getBySequence(int inningsId, int sequenceNumber);
  Future<void> updateWicketReplacement({required int ballEventId, required int replacementBatterId});
  Future<void> deleteById(int id);
}
