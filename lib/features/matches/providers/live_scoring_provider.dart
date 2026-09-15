import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/scoring/apply_scoring_action_service.dart';
import '../../../application/scoring/undo_scoring_action_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/innings/enums/innings_status.dart';
import '../../../domain/innings/models/innings.dart';
import '../../../domain/innings/models/innings_recalculation_context.dart';
import '../../../domain/innings/models/innings_state.dart';
import '../../../domain/innings/services/innings_recalculation_engine.dart';
import '../../../domain/matches/models/match.dart';
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
  LiveScoringState copyWith({Innings? innings, InningsState? score, int? selectedBowlerId, List<int>? activeTwoBowlerIds, bool? canUndo, int? manualStrikerId, int? manualNonStrikerId, bool clearManualBatters = false}) => LiveScoringState(innings: innings ?? this.innings, score: score ?? this.score, selectedBowlerId: selectedBowlerId ?? this.selectedBowlerId, activeTwoBowlerIds: activeTwoBowlerIds ?? this.activeTwoBowlerIds, canUndo: canUndo ?? this.canUndo, manualStrikerId: clearManualBatters ? null : (manualStrikerId ?? this.manualStrikerId), manualNonStrikerId: clearManualBatters ? null : (manualNonStrikerId ?? this.manualNonStrikerId));
}

class LiveScoringNotifier extends AsyncNotifier<LiveScoringState> {
  LiveScoringNotifier(this._inningsId); final int _inningsId; late final ApplyScoringActionService _applyService; late final UndoScoringActionService _undoService;
  @override Future<LiveScoringState> build() async {
    final inningsRepository = ref.watch(inningsRepositoryProvider); final ballEventRepository = ref.watch(ballEventRepositoryProvider);
    _applyService = ApplyScoringActionService(inningsRepository: inningsRepository, ballEventRepository: ballEventRepository); _undoService = UndoScoringActionService(inningsRepository: inningsRepository, ballEventRepository: ballEventRepository);
    final innings = await inningsRepository.getById(_inningsId); if (innings == null) throw StateError('Innings $_inningsId was not found.');
    final balls = await ballEventRepository.getForInnings(_inningsId); final target = await _applyService.targetForInnings(innings); final score = _recalculate(innings, balls, target: target);
    return LiveScoringState(innings: innings, score: score, selectedBowlerId: score.bowlerId == 0 ? innings.openingBowlerId : score.bowlerId, activeTwoBowlerIds: const <int>[], canUndo: balls.isNotEmpty);
  }
  void selectBowler(int bowlerId) => state = AsyncData(state.requireValue.copyWith(selectedBowlerId: bowlerId));
  void selectTwoBowlerPair(List<int> ids) { if (ids.length != 2 || ids.toSet().length != 2) throw ArgumentError('Select exactly two different bowlers.'); final c = state.requireValue; state = AsyncData(c.copyWith(activeTwoBowlerIds: List<int>.unmodifiable(ids), selectedBowlerId: c.selectedBowlerId ?? ids.first)); }
  void selectFinalOverBowler(int id) { final c = state.requireValue; if (!c.innings.twoBowlerMode || c.innings.oversPerInnings.isEven || c.score.completedOvers + 1 != c.innings.oversPerInnings) throw ArgumentError('A single bowler can only be selected for the final odd over.'); state = AsyncData(c.copyWith(activeTwoBowlerIds: List<int>.unmodifiable([id]), selectedBowlerId: id)); }
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
    final players = await ref.read(matchPlayersProvider(c.innings.matchId).future); final available = players.where((p) => p.teamId == c.innings.battingTeamId && p.isPlaying).map((p) => p.playerId).toSet();
    if (!available.contains(id)) throw ArgumentError('Replacement batter must be an available batting-team player.'); if (c.score.batters.containsKey(id)) throw ArgumentError('That player has already batted in this innings.');
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
  Future<void> scoreLegByeDelivery(int r) { if (r < 1) throw ArgumentError('Leg-bye delivery must contain at least one leg-bye run.'); return _apply(DeliveryInput(deliveryType: DeliveryType.legBye, legByeRuns: r); }
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
    final c = state.requireValue; if (!c.canUndo) return; state = const AsyncLoading();
    try { await _undoService.undo(inningsId: _inningsId); final balls = await ref.read(ballEventRepositoryProvider).getForInnings(_inningsId); final target = await _applyService.targetForInnings(c.innings); final score = _recalculate(c.innings, balls, target: target); state = AsyncData(c.copyWith(score: score, selectedBowlerId: score.bowlerId == 0 ? c.selectedBowlerId : score.bowlerId, canUndo: score.ballCount > 0, clearManualBatters: true)); ref.invalidate(inningsByMatchProvider(c.innings.matchId)); ref.invalidate(ballEventsByInningsProvider(_inningsId)); } catch (e, st) { state = AsyncData(c); Error.throwWithStackTrace(e, st); }
  }
  Future<void> _apply(DeliveryInput input) async {
    final c = state.requireValue; final bowlerId = c.selectedBowlerId; if (bowlerId == null || bowlerId <= 0) { final e = StateError('Select a bowler before scoring.'); state = AsyncData(c); Error.throwWithStackTrace(e, StackTrace.current); }
    try { final eligible = await _eligibleBowlerIds(c.innings); state = const AsyncLoading(); final result = await _applyService.apply(inningsId: _inningsId, input: input, bowlerId: bowlerId, eligibleBowlerIds: eligible, activeTwoBowlerIds: c.activeTwoBowlerIds, strikerIdOverride: c.manualStrikerId, nonStrikerIdOverride: c.manualNonStrikerId); state = AsyncData(c.copyWith(score: result.state, selectedBowlerId: result.rotation.currentBowlerId == 0 ? null : result.rotation.currentBowlerId, canUndo: true, clearManualBatters: true)); await _persistMatchCompletionIfFinal(c.innings); ref.invalidate(inningsByMatchProvider(c.innings.matchId)); ref.invalidate(ballEventsByInningsProvider(_inningsId)); } catch (e, st) { state = AsyncData(c); Error.throwWithStackTrace(e, st); }
  }
  Future<void> _persistMatchCompletionIfFinal(Innings currentInnings) async {
    if (currentInnings.inningsNumber != currentInnings.oversPerInnings && currentInnings.inningsNumber != (await ref.read(inningsRepositoryProvider).getForMatch(currentInnings.matchId)).length) {
      return;
    }
    final innings = await ref.read(inningsRepositoryProvider).getForMatch(currentInnings.matchId);
    if (innings.length < currentInnings.matchId) return;
    final match = await ref.read(matchRepositoryProvider).getById(currentInnings.matchId);
    if (match == null || match.status == MatchStatus.completed || innings.length < match.inningsCount) return;
    final sorted = [...innings]..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final states = <int, InningsState>{};
    for (final inning in sorted) {
      final balls = await ref.read(ballEventRepositoryProvider).getForInnings(inning.id);
      states[inning.id] = _recalculate(inning, balls);
    }
    final result = const MatchResultService().result(match: match, innings: sorted, states: states);
    if (!result.completed) return;
    await ref.read(matchRepositoryProvider).update(match.copyWith(status: MatchStatus.completed));
    ref.invalidate(matchByIdProvider(match.id));
    ref.invalidate(matchProvider);
  }
  Future<List<int>> _eligibleBowlerIds(Innings innings) async { final players = await ref.read(matchPlayersProvider(innings.matchId).future); return players.where((p) => p.teamId == innings.bowlingTeamId && p.isPlaying).map((p) => p.playerId).toList(growable: false); }
  InningsState _recalculate(Innings innings, List<BallEvent> balls, {int? target}) => const InningsRecalculationEngine().recalculate(InningsRecalculationContext(balls: balls, initialStrikerId: innings.openingStrikerId, initialNonStrikerId: innings.openingNonStrikerId, initialBowlerId: innings.openingBowlerId, ballsPerOver: innings.ballsPerOver, totalOvers: innings.oversPerInnings, target: target));
}
