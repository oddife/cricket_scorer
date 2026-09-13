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

  @override Future<List<BallEvent>> getForInnings(int inningsId) async =>
      events.where((event) => event.inningsId == inningsId).toList();
  @override
  Future<BallEvent?> getBySequence(int inningsId, int sequenceNumber) async {
    for (final event in events) {
      if (event.inningsId == inningsId && event.sequenceNumber == sequenceNumber) return event;
    }
    return null;
  }
  @override Future<void> deleteById(int id) async => events.removeWhere((event) => event.id == id);
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

DeliveryInput _legal([int runs = 0]) => DeliveryInput(deliveryType: DeliveryType.normal, batterRuns: runs);
const _wide = DeliveryInput(deliveryType: DeliveryType.wide, wideRuns: 1);
const _noBall = DeliveryInput(deliveryType: DeliveryType.noBall, noBallRuns: 1);

ApplyScoringActionService _service(Innings innings, _FakeBallEventRepository repository) =>
    ApplyScoringActionService(
      inningsRepository: _FakeInningsRepository(innings),
      ballEventRepository: repository,
    );

void main() {
  test('normal mode keeps one bowler for an over and requires a new bowler', () async {
    final repository = _FakeBallEventRepository();
    final service = _service(_innings(), repository);
    var result = await service.apply(inningsId: 1, input: _legal(), bowlerId: 20, eligibleBowlerIds: const [20, 21]);
    for (var i = 1; i < 6; i++) {
      result = await service.apply(inningsId: 1, input: _legal(), bowlerId: 20, eligibleBowlerIds: const [20, 21]);
    }
    expect(result.rotation.completedOver, isTrue);
    expect(result.rotation.requiresBowlerSelection, isTrue);
    expect(repository.events, hasLength(6));
    expect(() => service.apply(inningsId: 1, input: _legal(), bowlerId: 20, eligibleBowlerIds: const [20, 21]), throwsA(isA<StateError>()));
    final next = await service.apply(inningsId: 1, input: _legal(), bowlerId: 21, eligibleBowlerIds: const [20, 21]);
    expect(next.rotation.currentBowlerId, 21);
  });

  test('wide and no-ball do not consume legal balls', () async {
    final repository = _FakeBallEventRepository();
    final service = _service(_innings(), repository);
    final wide = await service.apply(inningsId: 1, input: _wide, bowlerId: 20, eligibleBowlerIds: const [20, 21]);
    expect(wide.state.legalBalls, 0);
    expect(wide.rotation.currentBowlerId, 20);
    final noBall = await service.apply(inningsId: 1, input: _noBall, bowlerId: 20, eligibleBowlerIds: const [20, 21]);
    expect(noBall.state.legalBalls, 0);
    expect(repository.events, hasLength(2));
  });

  test('2-Bowler Mode alternates A/B on every legal delivery', () async {
    final repository = _FakeBallEventRepository();
    final service = _service(_innings(twoBowlerMode: true, overs: 4), repository);
    var bowler = 20;
    for (var i = 0; i < 6; i++) {
      final result = await service.apply(
        inningsId: 1,
        input: _legal(),
        bowlerId: bowler,
        eligibleBowlerIds: const [20, 21, 22, 23],
        activeTwoBowlerIds: const [20, 21],
      );
      if (i < 5) bowler = result.rotation.currentBowlerId;
    }
    expect(repository.events.map((e) => e.bowlerId), [20, 21, 20, 21, 20, 21]);
  });

  test('illegal deliveries do not alter the A/B sequence', () async {
    final repository = _FakeBallEventRepository();
    final service = _service(_innings(twoBowlerMode: true), repository);
    await service.apply(inningsId: 1, input: _legal(), bowlerId: 20, eligibleBowlerIds: const [20, 21, 22, 23], activeTwoBowlerIds: const [20, 21]);
    await service.apply(inningsId: 1, input: _wide, bowlerId: 21, eligibleBowlerIds: const [20, 21, 22, 23], activeTwoBowlerIds: const [20, 21]);
    await service.apply(inningsId: 1, input: _noBall, bowlerId: 21, eligibleBowlerIds: const [20, 21, 22, 23], activeTwoBowlerIds: const [20, 21]);
    await service.apply(inningsId: 1, input: _legal(), bowlerId: 20, eligibleBowlerIds: const [20, 21, 22, 23], activeTwoBowlerIds: const [20, 21]);
    expect(repository.events.map((e) => e.bowlerId), [20, 21, 21, 20]);
    expect(repository.events.where((e) => e.isLegalBall), hasLength(2));
  });

  test('rejects a bowler outside the bowling XI', () async {
    final repository = _FakeBallEventRepository();
    final service = _service(_innings(), repository);
    expect(() => service.apply(inningsId: 1, input: _legal(), bowlerId: 99, eligibleBowlerIds: const [20, 21]), throwsA(isA<ArgumentError>()));
    expect(repository.events, isEmpty);
  });

  test('2-Bowler Mode rejects a bowler outside the active pair', () async {
    final repository = _FakeBallEventRepository();
    final service = _service(_innings(twoBowlerMode: true), repository);
    expect(() => service.apply(inningsId: 1, input: _legal(), bowlerId: 22, eligibleBowlerIds: const [20, 21, 22], activeTwoBowlerIds: const [20, 21]), throwsA(isA<ArgumentError>()));
  });

  test('application result contains persisted event, state and rotation', () async {
    final repository = _FakeBallEventRepository();
    final service = _service(_innings(), repository);
    final result = await service.apply(inningsId: 1, input: _legal(4), bowlerId: 20, eligibleBowlerIds: const [20, 21]);
    expect(result.ballEventId, 1);
    expect(result.state.score, 4);
    expect(result.state.legalBalls, 1);
    expect(result.state.batters[10]?.runs, 4);
    expect(result.rotation.currentBowlerId, 20);
  });
}
