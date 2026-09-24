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
      if (event.inningsId == inningsId && event.sequenceNumber == sequenceNumber) {
        return event;
      }
    }
    return null;
  }

  @override Future<void> deleteById(int id) async => events.removeWhere((event) => event.id == id);

  @override
  Future<void> updateWicketReplacement({
    required int ballEventId,
    required int replacementBatterId,
  }) async {}
}

Innings _innings({bool twoBowlerMode = false, int overs = 15}) => Innings(
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

DeliveryInput _legal([int runs = 0]) =>
    DeliveryInput(deliveryType: DeliveryType.normal, batterRuns: runs);

ApplyScoringActionService _service(
  Innings innings,
  _FakeBallEventRepository repository,
) =>
    ApplyScoringActionService(
      inningsRepository: _FakeInningsRepository(innings),
      ballEventRepository: repository,
    );

const _squad = [20, 21, 22, 23, 24, 25];

Future<void> _playBlock(
  ApplyScoringActionService service,
  _FakeBallEventRepository repo,
  List<int> pair,
) async {
  var bowler = pair.first;
  for (var i = 0; i < 12; i++) {
    final result = await service.apply(
      inningsId: 1,
      input: _legal(),
      bowlerId: bowler,
      eligibleBowlerIds: _squad,
      activeTwoBowlerIds: pair,
    );
    bowler = result.rotation.currentBowlerId;
  }
  expect(bowler, 0, reason: 'block must end with pair selection required');
}

Future<void> _playThreeBlocks(
  ApplyScoringActionService service,
  _FakeBallEventRepository repo,
) async {
  await _playBlock(service, repo, const [20, 21]);
  await _playBlock(service, repo, const [22, 23]);
  await _playBlock(service, repo, const [24, 25]);
}

void main() {
  test('A: a clean 15-over two-bowler match completes all 15 overs', () async {
    final repo = _FakeBallEventRepository();
    final service = _service(_innings(twoBowlerMode: true), repo);
    await _playThreeBlocks(service, repo);
    await _playBlock(service, repo, const [20, 21]);
    await _playBlock(service, repo, const [22, 23]);
    await _playBlock(service, repo, const [24, 25]);
    await _playBlock(service, repo, const [20, 21]);

    var finalOverBowler = 22;
    var last = await service.apply(
      inningsId: 1,
      input: _legal(),
      bowlerId: finalOverBowler,
      eligibleBowlerIds: _squad,
      activeTwoBowlerIds: [finalOverBowler],
    );
    for (var i = 1; i < 6; i++) {
      last = await service.apply(
        inningsId: 1,
        input: _legal(),
        bowlerId: finalOverBowler,
        eligibleBowlerIds: _squad,
        activeTwoBowlerIds: [finalOverBowler],
      );
    }

    expect(repo.events.where((e) => e.isLegalBall), hasLength(90));
    expect(last.state.inningsComplete, isTrue);
    expect(
      () => service.apply(
        inningsId: 1,
        input: _legal(),
        bowlerId: 22,
        eligibleBowlerIds: _squad,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('B: re-selecting the previous over pair at the block boundary rejects scoring', () async {
    final repo = _FakeBallEventRepository();
    final service = _service(_innings(twoBowlerMode: true), repo);
    await _playThreeBlocks(service, repo);
    final before = repo.events.length;

    for (var i = 0; i < 3; i++) {
      expect(
        () => service.apply(
          inningsId: 1,
          input: _legal(),
          bowlerId: 24,
          eligibleBowlerIds: _squad,
          activeTwoBowlerIds: const [24, 25],
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('cannot include a bowler from the previous over'),
        )),
      );
    }
    expect(repo.events, hasLength(before));
  });

  test('C: a rebuild that drops the active pair blocks every scoring press', () async {
    final repo = _FakeBallEventRepository();
    final service = _service(_innings(twoBowlerMode: true), repo);
    await _playThreeBlocks(service, repo);
    await service.apply(
      inningsId: 1,
      input: _legal(),
      bowlerId: 20,
      eligibleBowlerIds: _squad,
      activeTwoBowlerIds: const [20, 21],
    );
    final before = repo.events.length;

    for (var i = 0; i < 2; i++) {
      expect(
        () => service.apply(
          inningsId: 1,
          input: _legal(),
          bowlerId: 20,
          eligibleBowlerIds: _squad,
          activeTwoBowlerIds: const [],
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('requires exactly two active bowlers'),
        )),
      );
    }
    expect(repo.events, hasLength(before));
  });

  test('D: undo across the block boundary rejects the stale previous-block bowler', () async {
    final repo = _FakeBallEventRepository();
    final service = _service(_innings(twoBowlerMode: true), repo);
    await _playThreeBlocks(service, repo);
    await service.apply(
      inningsId: 1,
      input: _legal(),
      bowlerId: 20,
      eligibleBowlerIds: _squad,
      activeTwoBowlerIds: const [20, 21],
    );
    repo.events.removeLast();

    final before = repo.events.length;
    for (var i = 0; i < 2; i++) {
      expect(
        () => service.apply(
          inningsId: 1,
          input: _legal(),
          bowlerId: 25,
          eligibleBowlerIds: _squad,
          activeTwoBowlerIds: const [20, 21],
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('must be in the active pair'),
        )),
      );
    }
    expect(repo.events, hasLength(before));
  });
}
