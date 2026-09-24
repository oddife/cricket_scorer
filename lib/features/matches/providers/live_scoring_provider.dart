import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/scoring/apply_scoring_action_service.dart';
import '../../../application/scoring/undo_scoring_action_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/innings/enums/innings_status.dart';
import '../../../domain/innings/models/innings.dart';
import '../../../domain/innings/models/innings_recalculation_context.dart';
import '../../../domain/innings/models/innings_state.dart';
import '../../../domain/innings/services/innings_recalculation_engine.dart';
import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/services/match_result_service.dart';
import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/models/ball_event.dart';
import '../../../domain/scoring/models/delivery_input.dart';
import '../../../domain/scoring/models/wicket.dart';
import 'innings_provider.dart';
import 'match_provider.dart';

final liveScoringProvider = AsyncNotifierProvider.family<LiveScoringNotifier, LiveScoringState, int>(LiveScoringNotifier.new);

class LiveScoringState {
  const LiveScoringState({required this.innings, required this.score, required this.selectedBowlerId, required this.activeTwoBowlerIds, required this.canUndo, this.manualStrikerId, this.manualNonStrikerId});
  final Innings innings; final InningsState score; final int? selectedBowlerId; final List<int> activeTwoBowlerIds; final bool canUndo; final int? manualStrikerId; final int? manualNonStrikerId;
  int get liveStrikerId => manualStrikerId ?? score.strikerId;
  int get liveNonStrikerId => manualNonStrikerId ?? score.nonStrikerId;
  LiveScoringState copyWith({Innings? innings, InningsState? score, int? selectedBowlerId, List<int>? activeTwoBowlerIds, bool? canUndo, int? manualStrikerId, int? manualNonStrikerId, bool clearSelectedBowler = false, bool clearManualBatters = false}) => LiveScoringState(innings: innings ?? this.innings, score: score ?? this.score, selectedBowlerId: clearSelectedBowler ? null : (selectedBowlerId ?? this.selectedBowlerId), activeTwoBowlerIds: activeTwoBowlerIds ?? this.activeTwoBowlerIds, canUndo: canUndo ?? this.canUndo, manualStrikerId: clearManualBatters ? null : (manualStrikerId ?? this.manualStrikerId), manualNonStrikerId: clearManualBatters ? null : (manualNonStrikerId ?? this.manualNonStrikerId));
}

class LiveScoringNotifier extends AsyncNotifier<LiveScoringState> {
  LiveScoringNotifier(this._inningsId); final int _inningsId; late final ApplyScoringActionService _applyService; late final UndoScoringActionService _undoService;
  @override Future<LiveScoringState> build() async {
    final inningsRepository = ref.watch(inningsRepositoryProvider);
    final ballEventRepository = ref.watch(ballEventRepositoryProvider);
    _applyService = ApplyScoringActionService(
      inningsRepository: inningsRepository,
      ballEventRepository: ballEventRepository,
    );
    _undoService = UndoScoringActionService(
      inningsRepository: inningsRepository,
      ballEventRepository: ballEventRepository,
    );
    final innings = await inningsRepository.getById(_inningsId);
    if (innings == null) throw StateError('Innings $_inningsId was not found.');
    final balls = await ballEventRepository.getForInnings(_inningsId);
    final target = await _applyService.targetForInnings(innings);
    final score = _recalculate(innings, balls, target: target);
    final persistedPair = innings.twoBowlerMode &&
            innings.activeTwoBowlerOneId != null &&
            innings.activeTwoBowlerTwoId != null
        ? <int>[innings.activeTwoBowlerOneId!, innings.activeTwoBowlerTwoId!]
        : const <int>[];
    final restoredPair = persistedPair.isNotEmpty
        ? List<int>.unmodifiable(persistedPair)
        : _restoreTwoBowlerPair(innings, balls);
    final restoredBowler = score.bowlerId == 0
        ? (innings.twoBowlerMode && restoredPair.isEmpty
            ? null
            : innings.openingBowlerId)
        : score.bowlerId;
    return LiveScoringState(
      innings: innings,
      score: score,
      selectedBowlerId: restoredBowler,
      activeTwoBowlerIds: restoredPair,
      canUndo: balls.isNotEmpty,
    );
  }
  List<int> _restoreTwoBowlerPair(Innings innings, List<BallEvent> balls) {
    if (!innings.twoBowlerMode || balls.isEmpty) return const <int>[];

    final currentOverNumber = balls.last.overNumber;
    final currentOverLegalBalls = balls
        .where((ball) => ball.overNumber == currentOverNumber && ball.isLegalBall)
        .length;

    // Once an even-numbered over has completed, the previous two-over block
    // is finished and the scorer must explicitly select the next pair.
    if (currentOverNumber.isEven &&
        currentOverLegalBalls >= innings.ballsPerOver) {
      return const <int>[];
    }

    // A two-bowler block spans two consecutive overs. When the current over is
    // the first over of the block, the pair may still be fully reconstructible
    // from the immediately preceding over boundary only when that block had
    // already started. Prefer the current block's own history; if only one
    // bowler has appeared so far, recover the other bowler from the block's
    // first over rather than dropping the pair.
    final blockStartOver =
        currentOverNumber.isOdd ? currentOverNumber : currentOverNumber - 1;

    final ids = <int>[];
    for (final ball in balls.where(
      (ball) =>
          ball.overNumber >= blockStartOver &&
          ball.overNumber <= currentOverNumber,
    )) {
      if (ball.bowlerId > 0 && !ids.contains(ball.bowlerId)) {
        ids.add(ball.bowlerId);
      }
      if (ids.length == 2) break;
    }

    // During a rebuild after the first delivery of a new odd over, history
    // contains only the bowler who has delivered so far. The pair cannot be
    // inferred from that single delivery, so look at the completed immediately
    // preceding over only as a fallback. That over is the second over of the
    // previous block and must not become the active pair unless one of its
    // bowlers also appears in the new block.
    if (ids.length == 1 && blockStartOver > 1) {
      final previousOver = blockStartOver - 1;
      for (final ball in balls.where((ball) => ball.overNumber == previousOver)) {
        if (ball.bowlerId > 0 && !ids.contains(ball.bowlerId)) {
          // Do not invent a new pair from a previous block. Only use this
          // fallback when the current block has evidence of the same bowler.
          break;
        }
      }
    }

    return ids.length == 2 ? List<int>.unmodifiable(ids) : const <int>[];
  }
  void selectBowler(int bowlerId) => state = AsyncData(state.requireValue.copyWith(selectedBowlerId: bowlerId));
  Future<void> selectTwoBowlerPair(List<int> ids) async {
    if (ids.length != 2 || ids.toSet().length != 2) {
      throw ArgumentError('Select exactly two different bowlers.');
    }
    final c = state.requireValue;
    final innings = c.innings.withActiveTwoBowlerPair(ids);
    await ref.read(inningsRepositoryProvider).update(innings);
    state = AsyncData(c.copyWith(
      innings: innings,
      activeTwoBowlerIds: List<int>.unmodifiable(ids),
      selectedBowlerId: ids.first,
    ));
  }

  Future<void> selectFinalOverBowler(int id) async {
    final c = state.requireValue;
    if (!c.innings.twoBowlerMode ||
        c.innings.oversPerInnings.isEven ||
        c.score.completedOvers + 1 != c.innings.oversPerInnings) {
      throw ArgumentError(
        'A single bowler can only be selected for the final odd over.',
      );
    }
    final innings = c.innings.withActiveFinalOverBowler(id);
    await ref.read(inningsRepositoryProvider).update(innings);
    state = AsyncData(c.copyWith(
      innings: innings,
      activeTwoBowlerIds: List<int>.unmodifiable([id]),
      selectedBowlerId: id,
    ));
  }
  Future<void> selectBatters({required int strikerId, required int nonStrikerId}) async {
    final c = state.requireValue; if (c.score.inningsComplete) throw StateError('The innings is complete.'); if (c.score.requiresBatterReplacement) throw StateError('Select the replacement batter first.'); if (strikerId <= 0 || nonStrikerId <= 0 || strikerId == nonStrikerId) throw ArgumentError('Select two different batters.');
    final players = await ref.read(matchPlayersProvider(c.innings.matchId).future); final available = players.where((p) => p.teamId == c.innings.battingTeamId && p.isPlaying).map((p) => p.playerId).toSet();
    if (!available.contains(strikerId) || !available.contains(nonStrikerId)) throw ArgumentError('Selected batters must be available batting-team players.');
    if (!c.score.batters.containsKey(strikerId) || !c.score.batters.containsKey(nonStrikerId)) throw ArgumentError('Only batters already participating in the innings can be manually selected.');
    if (c.score.batters[strikerId]?.isOut == true || c.score.batters[nonStrikerId]?.isOut == true) throw ArgumentError('A dismissed batter cannot be selected.');
    state = AsyncData(c.copyWith(manualStrikerId: strikerId, manualNonStrikerId: nonStrikerId));
  }
  Future<void> swapBatters() async { final c = state.requireValue; await selectBatters(strikerId: c.liveNonStrikerId, nonStrikerId: c.liveStrikerId); }
  Future<void> selectReplacementBatter(int id) async {
    final c = state.requireValue; if (!c.score.requiresBatterReplacement) throw StateError('No batter replacement is currently required.');
    final players = await ref.read(matchPlayersProvider(c.innings.matchId).future); final available = players.where((p) => p.teamId == c.innings.battingTeamId && p.isPlaying).map((p) => p.playerId).toSet(); if (!available.contains(id)) throw ArgumentError('Replacement batter must be an available batting-team player.'); if (c.score.batters.containsKey(id)) throw ArgumentError('That player has already batted in this innings.');
    final balls = await ref.read(ballEventRepositoryProvider).getForInnings(_inningsId); if (balls.isEmpty || balls.last.wicket == null) throw StateError('Unable to locate the wicket requiring a replacement.');
    await ref.read(ballEventRepositoryProvider).updateWicketReplacement(ballEventId: balls.last.id, replacementBatterId: id);
    final refreshed = await ref.read(ballEventRepositoryProvider).getForInnings(_inningsId); final target = await _applyService.targetForInnings(c.innings); final score = _recalculate(c.innings, refreshed, target: target); state = AsyncData(c.copyWith(score: score, clearManualBatters: true));
  }
  Future<void> scoreRuns(int r) => _apply(DeliveryInput(deliveryType: DeliveryType.normal, batterRuns: r));
  Future<void> scoreWide(int r) => _apply(DeliveryInput(deliveryType: DeliveryType.wide, wideRuns: r));
  Future<void> scoreNoBall({int batterRuns = 0}) => _apply(DeliveryInput(deliveryType: DeliveryType.noBall, batterRuns: batterRuns, noBallRuns: 1));
  Future<void> scoreNoBallDelivery(DeliveryInput input) { if (input.deliveryType != DeliveryType.noBall || input.noBallRuns != 1) throw ArgumentError('No-ball delivery must contain the one-run no-ball penalty.'); return _apply(input); }
  Future<void> scoreBye(int r) => _apply(DeliveryInput(deliveryType: DeliveryType.bye, byeRuns: r));
  Future<void> scoreByeDelivery(int r) { if (r < 1) throw ArgumentError('Bye delivery must contain at least one bye run.'); return _apply(DeliveryInput(deliveryType: DeliveryType.bye, byeRuns: r)); }
  Future<void> scoreLegBye(int r) => _apply(DeliveryInput(deliveryType: DeliveryType.legBye, legByeRuns: r));
  Future<void> scoreLegByeDelivery(int r) { if (r < 1) throw ArgumentError('Leg-bye delivery must contain at least one leg-bye run.'); return _apply(DeliveryInput(deliveryType: DeliveryType.legBye, legByeRuns: r)); }
  Future<void> scoreWicket(Wicket w) => scoreWicketDelivery(DeliveryInput(deliveryType: DeliveryType.normal, wicket: w));
  Future<void> scoreWicketDelivery(DeliveryInput input) => _apply(input);
  Future<void> endInnings() async {
    final c = state.requireValue;
    if (c.innings.status == InningsStatus.ended || c.score.inningsComplete) return;
    final ended = c.innings.copyWith(status: InningsStatus.ended, completedAt: DateTime.now());
    await ref.read(inningsRepositoryProvider).update(ended);
    state = AsyncData(c.copyWith(innings: ended));
    await _persistMatchCompletionIfFinal(ended);
    ref.invalidate(inningsByMatchProvider(c.innings.matchId));
  }
  Future<void> undo() async {
    final c = state.requireValue;
    if (!c.canUndo) return;
    state = const AsyncLoading();
    try {
      await _undoService.undo(inningsId: _inningsId);
      final balls =
          await ref.read(ballEventRepositoryProvider).getForInnings(_inningsId);
      final target = await _applyService.targetForInnings(c.innings);
      final score = _recalculate(c.innings, balls, target: target);
      final historyPair = _restoreTwoBowlerPair(c.innings, balls);
      final persistedPair = c.innings.twoBowlerMode &&
              c.innings.activeTwoBowlerOneId != null &&
              c.innings.activeTwoBowlerTwoId != null
          ? <int>[
              c.innings.activeTwoBowlerOneId!,
              c.innings.activeTwoBowlerTwoId!,
            ]
          : const <int>[];
      final restoredPair = historyPair.isNotEmpty ? historyPair : persistedPair;
      final restoredBowler = score.bowlerId == 0 ? null : score.bowlerId;
      final safeSelectedBowler = c.innings.twoBowlerMode &&
              restoredPair.isNotEmpty &&
              !restoredPair.contains(restoredBowler)
          ? restoredPair.first
          : restoredBowler;

      state = AsyncData(
        c.copyWith(
          score: score,
          selectedBowlerId: safeSelectedBowler,
          activeTwoBowlerIds: restoredPair,
          canUndo: score.ballCount > 0,
          clearManualBatters: true,
          clearSelectedBowler: safeSelectedBowler == null,
        ),
      );
      ref.invalidate(inningsByMatchProvider(c.innings.matchId));
      ref.invalidate(ballEventsByInningsProvider(_inningsId));
    } catch (e, st) {
      state = AsyncData(c);
      Error.throwWithStackTrace(e, st);
    }
  }
  Future<void> _apply(DeliveryInput input) async {
    final c = state.requireValue;
    final bowlerId = c.selectedBowlerId;
    if (bowlerId == null || bowlerId <= 0) {
      final e = StateError('Select a bowler before scoring.');
      state = AsyncData(c);
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    try {
      final eligible = await _eligibleBowlerIds(c.innings);
      state = const AsyncLoading();
      final result = await _applyService.apply(
        inningsId: _inningsId,
        input: input,
        bowlerId: bowlerId,
        eligibleBowlerIds: eligible,
        activeTwoBowlerIds: c.activeTwoBowlerIds,
        strikerIdOverride: c.manualStrikerId,
        nonStrikerIdOverride: c.manualNonStrikerId,
      );
      final completed = result.rotation.twoBowlerBlockCompleted;
      final nextActive = completed
          ? const <int>[]
          : c.activeTwoBowlerIds;
      final nextInnings =
          completed ? c.innings.clearActiveTwoBowlerPair() : c.innings;
      if (completed) {
        await ref.read(inningsRepositoryProvider).update(nextInnings);
      }
      state = AsyncData(c.copyWith(
        innings: nextInnings,
        score: result.state,
        selectedBowlerId:
            result.rotation.currentBowlerId == 0
                ? null
                : result.rotation.currentBowlerId,
        activeTwoBowlerIds: nextActive,
        canUndo: true,
        clearSelectedBowler: completed || result.rotation.currentBowlerId == 0,
        clearManualBatters: true,
      ));
      await _persistMatchCompletionIfFinal(c.innings);
      ref.invalidate(inningsByMatchProvider(c.innings.matchId));
      ref.invalidate(ballEventsByInningsProvider(_inningsId));
    } catch (e, st) {
      state = AsyncData(c);
      Error.throwWithStackTrace(e, st);
    }
  }
  Future<void> _persistMatchCompletionIfFinal(Innings currentInnings) async {
    final match = await ref.read(matchRepositoryProvider).getById(currentInnings.matchId);
    if (match == null || match.status == MatchStatus.completed || currentInnings.inningsNumber != match.inningsCount) return;
    final currentBalls = await ref.read(ballEventRepositoryProvider).getForInnings(currentInnings.id);
    final currentTarget = await _applyService.targetForInnings(currentInnings);
    final currentState = _recalculate(currentInnings, currentBalls, target: currentTarget);
    if (currentState.inningsComplete) {
      await ref.read(matchRepositoryProvider).update(match.copyWith(status: MatchStatus.completed));
      ref.invalidate(matchByIdProvider(match.id));
      ref.invalidate(matchProvider);
      return;
    }
    final innings = await ref.read(inningsRepositoryProvider).getForMatch(currentInnings.matchId);
    if (innings.length < match.inningsCount) return;
    final sorted = [...innings]..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final states = <int, InningsState>{};
    final service = const MatchResultService();
    for (final inning in sorted) {
      final balls = await ref.read(ballEventRepositoryProvider).getForInnings(inning.id);
      final target = service.targetForInnings(match: match, innings: sorted, states: states, inningsNumber: inning.inningsNumber);
      states[inning.id] = _recalculate(inning, balls, target: target);
    }
    final result = service.result(match: match, innings: sorted, states: states);
    if (!result.completed) return;
    await ref.read(matchRepositoryProvider).update(match.copyWith(status: MatchStatus.completed));
    ref.invalidate(matchByIdProvider(match.id));
    ref.invalidate(matchProvider);
  }
  Future<List<int>> _eligibleBowlerIds(Innings innings) async { final players = await ref.read(matchPlayersProvider(innings.matchId).future); return players.where((p) => p.teamId == innings.bowlingTeamId && p.isPlaying).map((p) => p.playerId).toList(growable: false); }
  InningsState _recalculate(Innings innings, List<BallEvent> balls, {int? target}) => const InningsRecalculationEngine().recalculate(InningsRecalculationContext(balls: balls, initialStrikerId: innings.openingStrikerId, initialNonStrikerId: innings.openingNonStrikerId, initialBowlerId: innings.openingBowlerId, ballsPerOver: innings.ballsPerOver, totalOvers: innings.oversPerInnings, target: target));
}