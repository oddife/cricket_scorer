import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/scoring/apply_scoring_action_service.dart';
import '../../../application/scoring/undo_scoring_action_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/innings/models/innings.dart';
import '../../../domain/innings/models/innings_recalculation_context.dart';
import '../../../domain/innings/models/innings_state.dart';
import '../../../domain/innings/services/innings_recalculation_engine.dart';
import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/models/ball_event.dart';
import '../../../domain/scoring/models/delivery_input.dart';
import '../../../domain/scoring/models/wicket.dart';
import 'innings_provider.dart';
import 'match_provider.dart';

final liveScoringProvider = AsyncNotifierProvider.family<LiveScoringNotifier, LiveScoringState, int>(LiveScoringNotifier.new);

class LiveScoringState {
  const LiveScoringState({required this.innings, required this.score, required this.selectedBowlerId, required this.activeTwoBowlerIds, required this.canUndo, this.manualStrikerId, this.manualNonStrikerId});
  final Innings innings;
  final InningsState score;
  final int? selectedBowlerId;
  final List<int> activeTwoBowlerIds;
  final bool canUndo;
  final int? manualStrikerId;
  final int? manualNonStrikerId;
  int get liveStrikerId => manualStrikerId ?? score.strikerId;
  int get liveNonStrikerId => manualNonStrikerId ?? score.nonStrikerId;

  LiveScoringState copyWith({Innings? innings, InningsState? score, int? selectedBowlerId, List<int>? activeTwoBowlerIds, bool? canUndo, int? manualStrikerId, int? manualNonStrikerId, bool clearManualBatters = false}) => LiveScoringState(
        innings: innings ?? this.innings,
        score: score ?? this.score,
        selectedBowlerId: selectedBowlerId ?? this.selectedBowlerId,
        activeTwoBowlerIds: activeTwoBowlerIds ?? this.activeTwoBowlerIds,
        canUndo: canUndo ?? this.canUndo,
        manualStrikerId: clearManualBatters ? null : (manualStrikerId ?? this.manualStrikerId),
        manualNonStrikerId: clearManualBatters ? null : (manualNonStrikerId ?? this.manualNonStrikerId),
      );
}

class LiveScoringNotifier extends AsyncNotifier<LiveScoringState> {
  LiveScoringNotifier(this._inningsId);
  final int _inningsId;
  late final ApplyScoringActionService _applyService;
  late final UndoScoringActionService _undoService;

  @override
  Future<LiveScoringState> build() async {
    final inningsRepository = ref.watch(inningsRepositoryProvider);
    final ballEventRepository = ref.watch(ballEventRepositoryProvider);
    _applyService = ApplyScoringActionService(inningsRepository: inningsRepository, ballEventRepository: ballEventRepository);
    _undoService = UndoScoringActionService(inningsRepository: inningsRepository, ballEventRepository: ballEventRepository);
    final innings = await inningsRepository.getById(_inningsId);
    if (innings == null) throw StateError('Innings $_inningsId was not found.');
    final balls = await ballEventRepository.getForInnings(_inningsId);
    final target = await _applyService.targetForInnings(innings);
    final score = _recalculate(innings, balls, target: target);
    return LiveScoringState(innings: innings, score: score, selectedBowlerId: score.bowlerId == 0 ? innings.openingBowlerId : score.bowlerId, activeTwoBowlerIds: const <int>[], canUndo: balls.isNotEmpty);
  }

  void selectBowler(int bowlerId) => state = AsyncData(state.requireValue.copyWith(selectedBowlerId: bowlerId));

  void selectTwoBowlerPair(List<int> bowlerIds) {
    if (bowlerIds.length != 2 || bowlerIds.toSet().length != 2) throw ArgumentError('Select exactly two different bowlers.');
    final current = state.requireValue;
    state = AsyncData(current.copyWith(activeTwoBowlerIds: List<int>.unmodifiable(bowlerIds), selectedBowlerId: current.selectedBowlerId ?? bowlerIds.first));
  }

  void selectFinalOverBowler(int bowlerId) {
    final current = state.requireValue;
    if (!current.innings.twoBowlerMode || current.innings.oversPerInnings.isEven || current.score.completedOvers + 1 != current.innings.oversPerInnings) throw ArgumentError('A single bowler can only be selected for the final odd over.');
    state = AsyncData(current.copyWith(activeTwoBowlerIds: List<int>.unmodifiable([bowlerId]), selectedBowlerId: bowlerId));
  }

  Future<void> selectBatters({required int strikerId, required int nonStrikerId}) async {
    final current = state.requireValue;
    if (current.score.inningsComplete) throw StateError('The innings is complete.');
    if (current.score.requiresBatterReplacement) throw StateError('Select the replacement batter first.');
    if (strikerId <= 0 || nonStrikerId <= 0 || strikerId == nonStrikerId) throw ArgumentError('Select two different batters.');
    final players = await ref.read(matchPlayersProvider(current.innings.matchId).future);
    final available = players.where((p) => p.teamId == current.innings.battingTeamId && p.isPlaying).map((p) => p.playerId).toSet();
    if (!available.contains(strikerId) || !available.contains(nonStrikerId)) throw ArgumentError('Selected batters must be available batting-team players.');
    if (current.score.batters[strikerId]?.isOut == true || current.score.batters[nonStrikerId]?.isOut == true) throw ArgumentError('A dismissed batter cannot be selected.');
    state = AsyncData(current.copyWith(manualStrikerId: strikerId, manualNonStrikerId: nonStrikerId));
  }

  Future<void> swapBatters() async {
    final current = state.requireValue;
    await selectBatters(strikerId: current.liveNonStrikerId, nonStrikerId: current.liveStrikerId);
  }

  Future<void> selectReplacementBatter(int playerId) async {
    final current = state.requireValue;
    if (!current.score.requiresBatterReplacement) throw StateError('No batter replacement is currently required.');
    final players = await ref.read(matchPlayersProvider(current.innings.matchId).future);
    final available = players.where((p) => p.teamId == current.innings.battingTeamId && p.isPlaying).map((p) => p.playerId).toSet();
    if (!available.contains(playerId)) throw ArgumentError('Replacement batter must be an available batting-team player.');
    if (current.score.batters.containsKey(playerId)) throw ArgumentError('That player has already batted in this innings.');
    final balls = await ref.read(ballEventRepositoryProvider).getForInnings(_inningsId);
    if (balls.isEmpty || balls.last.wicket == null) throw StateError('Unable to locate the wicket requiring a replacement.');
    await ref.read(ballEventRepositoryProvider).updateWicketReplacement(ballEventId: balls.last.id, replacementBatterId: playerId);
    final refreshed = await ref.read(ballEventRepositoryProvider).getForInnings(_inningsId);
    final target = await _applyService.targetForInnings(current.innings);
    final score = _recalculate(current.innings, refreshed, target: target);
    state = AsyncData(current.copyWith(score: score, clearManualBatters: true));
  }

  Future<void> scoreRuns(int runs) => _apply(DeliveryInput(deliveryType: DeliveryType.normal, batterRuns: runs));
  Future<void> scoreWide(int runs) => _apply(DeliveryInput(deliveryType: DeliveryType.wide, wideRuns: runs));
  Future<void> scoreNoBall({int batterRuns = 0}) => _apply(DeliveryInput(deliveryType: DeliveryType.noBall, batterRuns: batterRuns, noBallRuns: 1));
  Future<void> scoreNoBallDelivery(DeliveryInput input) { if (input.deliveryType != DeliveryType.noBall || input.noBallRuns != 1) throw ArgumentError('No-ball delivery must contain the one-run no-ball penalty.'); return _apply(input); }
  Future<void> scoreBye(int runs) => _apply(DeliveryInput(deliveryType: DeliveryType.bye, byeRuns: runs));
  Future<void> scoreByeDelivery(int runs) { if (runs < 1) throw ArgumentError('Bye delivery must contain at least one bye run.'); return _apply(DeliveryInput(deliveryType: DeliveryType.bye, byeRuns: runs)); }
  Future<void> scoreLegBye(int runs) => _apply(DeliveryInput(deliveryType: DeliveryType.legBye, legByeRuns: runs));
  Future<void> scoreLegByeDelivery(int runs) { if (runs < 1) throw ArgumentError('Leg-bye delivery must contain at least one leg-bye run.'); return _apply(DeliveryInput(deliveryType: DeliveryType.legBye, legByeRuns: runs)); }
  Future<void> scoreWicket(Wicket wicket) => scoreWicketDelivery(DeliveryInput(deliveryType: DeliveryType.normal, wicket: wicket));
  Future<void> scoreWicketDelivery(DeliveryInput input) => _apply(input);

  Future<void> undo() async {
    final current = state.requireValue;
    if (!current.canUndo) return;
    state = const AsyncLoading();
    try {
      await _undoService.undo(inningsId: _inningsId);
      final balls = await ref.read(ballEventRepositoryProvider).getForInnings(_inningsId);
      final target = await _applyService.targetForInnings(current.innings);
      final score = _recalculate(current.innings, balls, target: target);
      state = AsyncData(current.copyWith(score: score, selectedBowlerId: score.bowlerId == 0 ? current.selectedBowlerId : score.bowlerId, canUndo: score.ballCount > 0, clearManualBatters: true));
      ref.invalidate(inningsByMatchProvider(current.innings.matchId));
    } catch (error, stackTrace) { state = AsyncData(current); Error.throwWithStackTrace(error, stackTrace); }
  }

  Future<void> _apply(DeliveryInput input) async {
    final current = state.requireValue;
    final bowlerId = current.selectedBowlerId;
    if (bowlerId == null || bowlerId <= 0) { final error = StateError('Select a bowler before scoring.'); state = AsyncData(current); Error.throwWithStackTrace(error, StackTrace.current); }
    try {
      final eligibleBowlerIds = await _eligibleBowlerIds(current.innings);
      state = const AsyncLoading();
      final result = await _applyService.apply(inningsId: _inningsId, input: input, bowlerId: bowlerId, eligibleBowlerIds: eligibleBowlerIds, activeTwoBowlerIds: current.activeTwoBowlerIds, strikerIdOverride: current.manualStrikerId, nonStrikerIdOverride: current.manualNonStrikerId);
      final nextBowler = result.rotation.currentBowlerId;
      state = AsyncData(current.copyWith(score: result.state, selectedBowlerId: nextBowler == 0 ? null : nextBowler, canUndo: true, clearManualBatters: true));
      ref.invalidate(inningsByMatchProvider(current.innings.matchId));
    } catch (error, stackTrace) { state = AsyncData(current); Error.throwWithStackTrace(error, stackTrace); }
  }

  Future<List<int>> _eligibleBowlerIds(Innings innings) async {
    final players = await ref.read(matchPlayersProvider(innings.matchId).future);
    return players.where((p) => p.teamId == innings.bowlingTeamId && p.isPlaying).map((p) => p.playerId).toList(growable: false);
  }

  InningsState _recalculate(Innings innings, List<BallEvent> balls, {int? target}) => const InningsRecalculationEngine().recalculate(InningsRecalculationContext(balls: balls, initialStrikerId: innings.openingStrikerId, initialNonStrikerId: innings.openingNonStrikerId, initialBowlerId: innings.openingBowlerId, ballsPerOver: innings.ballsPerOver, totalOvers: innings.oversPerInnings, target: target));
}
