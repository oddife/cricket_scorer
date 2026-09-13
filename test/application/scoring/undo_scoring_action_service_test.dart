import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/data/repositories/ball_event_repository.dart';
import 'package:cricket_scorer/data/repositories/innings_repository.dart';
import 'package:cricket_scorer/domain/innings/models/innings.dart';
import 'package:cricket_scorer/domain/innings/enums/innings_status.dart';
import 'package:cricket_scorer/domain/scoring/models/ball_event.dart';
import 'package:cricket_scorer/application/scoring/undo_scoring_action_service.dart';

class _FakeInningsRepository implements InningsRepository {
  _FakeInningsRepository(this.innings);
  final Innings innings;
  @override Future<Innings?> getById(int inningsId) async => innings;
  @override Future<Innings?> getByMatchAndNumber(int matchId, int inningsNumber) async => innings;
  @override Future<List<Innings>> getForMatch(int matchId) async => [innings];
  @override Future<Innings> create(Innings innings) async => innings;
  @override Future<void> update(Innings innings) async {}
}

class _FakeBallEventRepository implements BallEventRepository {
  _FakeBallEventRepository(this.events);
  final List<BallEvent> events;
  @override Future<BallEvent> create(BallEvent event) async { events.add(event); return event; }
  @override Future<List<BallEvent>> getForInnings(int inningsId) async => [...events];
  @override Future<BallEvent?> getBySequence(int inningsId, int sequenceNumber) async =>
      events.where((e) => e.inningsId == inningsId && e.sequenceNumber == sequenceNumber).isEmpty
          ? null
          : events.where((e) => e.inningsId == inningsId && e.sequenceNumber == sequenceNumber).first;
  @override Future<void> deleteById(int id) async { events.removeWhere((e) => e.id == id); }
}

void main() {
  test('undo guards against empty history', () async {
    final innings = Innings(
      id: 1,
      matchId: 1,
      inningsNumber: 1,
      battingTeamId: 1,
      bowlingTeamId: 2,
      openingStrikerId: 10,
      openingNonStrikerId: 11,
      openingBowlerId: 20,
      oversPerInnings: 10,
      ballsPerOver: 6,
      twoBowlerMode: false,
      status: InningsStatus.live,
      startedAt: DateTime(2026),
      completedAt: null,
    );

    final balls = <BallEvent>[];
    final service = UndoScoringActionService(
      inningsRepository: _FakeInningsRepository(innings),
      ballEventRepository: _FakeBallEventRepository(balls),
    );

    expect(
      () => service.undo(inningsId: 1),
      throwsA(isA<StateError>()),
    );
  });
}
