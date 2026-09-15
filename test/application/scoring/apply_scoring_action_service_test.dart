import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/application/scoring/apply_scoring_action_service.dart';
import 'package:cricket_scorer/data/repositories/ball_event_repository.dart';
import 'package:cricket_scorer/data/repositories/innings_repository.dart';
import 'package:cricket_scorer/domain/innings/enums/innings_status.dart';
import 'package:cricket_scorer/domain/innings/models/innings.dart';
import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/models/ball_event.dart';
import 'package:cricket_scorer/domain/scoring/models/delivery_input.dart';

class _FakeInningsRepository implements InningsRepository {
  _FakeInningsRepository(this.innings);
  final Innings innings;

  @override Future<Innings?> getById(int inningsId) async => innings;
  @override Future<Innings?> getByMatchAndNumber(int matchId, int inningsNumber) async => innings;
  @override Future<List<Innings>> getForMatch(int matchId) async => [innings];
  @override Future<Innings> create(Innings value) async => value;
  @override Future<void> update(Innings value) async {}
}

class _FakeBallEventRepository implements BallEventRepository {
  _FakeBallEventRepository([List<BallEvent>? initial]) : events = [...?initial];
  final List<BallEvent> events;

  @override
  Future<BallEvent> create(BallEvent event) async {
    final persisted = BallEvent(
      id: events.length + 1,
      inningsId: event.inningsId,
      sequenceNumber: event.sequenceNumber,
      overNumber: event.overNumber,
      legalBallNumber: event.legalBallNumber,
      bowlerId: event.bowlerId,
      strikerId: event.strikerId,
      nonStrikerId: event.nonStrikerId,
      deliveryType: event.deliveryType,
      isLegalBall: event.isLegalBall,
      batterRuns: event.batterRuns,
      byeRuns: event.byeRuns,
      legByeRuns: event.legByeRuns,
      wideRuns: event.wideRuns,
      noBallRuns: event.noBallRuns,
      totalRuns: event.totalRuns,
      wicket: event.wicket,
      timestamp: event.timestamp,
    );
    events.add(persisted);
    return persisted;
  }

  @override
  Future<List<BallEvent>> getForInnings(int inningsId) async =>
      events.where((event) => event.inningsId == inningsId).toList();

  @override
  Future<BallEvent?> getBySequence(int inningsId, int sequenceNumber) async {
    for (final event in events) {
      if (event.inningsId == inningsId && event.sequenceNumber == sequenceNumber) {
        return event;
      }
    }
    return null;
  }

  @override
  Future<void> deleteById(int id) async =>
      events.removeWhere((event) => event.id == id);

  @override
  Future<void> updateWicketReplacement({
    required int ballEventId,
    required int replacementBatterId,
  }) async {}
}

Innings _innings({bool twoBowlerMode = false, int overs = 10}) => Innings(
      id: 1,
      matchId: 1,
      inningsNumber: 1,
      battingTeamId: 1,
      bowlingTeamId: 2,
      openingStrikerId: 10,
      openingNonStrikerId: 11,
      openingBowlerId: 20,
      oversPerInnings: overs,
      ballsPerOver: 6,
      twoBowlerMode: twoBowlerMode,
      status: InningsStatus.live,
      startedAt: DateTime(2026),
    );
