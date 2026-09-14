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
import 'match_provider.dart';

final liveScoringProvider = AsyncNotifierProvider.family<
    LiveScoringNotifier, LiveScoringState, int>(LiveScoringNotifier.new);

class LiveScoringState {
  const LiveScoringState({
    required this.innings,
    required this.score,
    required this.selectedBowlerId,
    required this.activeTwoBowlerIds,
    required this.canUndo,
  });

  final Innings innings;
  final InningsState score;
  final int? selectedBowlerId;
  final List<int> activeTwoBowlerIds;
  final bool canUndo;

  LiveScoringState copyWith({
    Innings? innings,
    InningsState? score,
    int? selectedBowlerId,
    List<int>? activeTwoBowlerIds,
    bool? canUndo,
  }) {
    return LiveScoringState(
      innings: innings ?? this.innings,
      score: score ?? this.score,
      selectedBowlerId: selectedBowlerId ?? this.selectedBowlerId,
      activeTwoBowlerIds: activeTwoBowlerIds ?? this.activeTwoBowlerIds,
      canUndo: canUndo ?? this.canUndo,
    );
  }
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
    _applyService = ApplyScoringActionService(
      inningsRepository: inningsRepository,
      ballEventRepository: ballEventRepository,
    );
    _undoService = UndoScoringActionService(
      inningsRepository: inningsRepository,
      ballEventRepository: ballEventRepository,
    );

    final innings = await inningsRepository.getById(_inningsId);
    if (innings == null) {
      throw StateError('Innings $_inningsId was not found.');
    }

    final balls = await ballEventRepository.getForInnings(_inningsId);
    final score = _recalculate(innings, balls);
    return LiveScoringState(
      innings: innings,
      score: score,
      selectedBowlerId:
          score.bowlerId == 0 ? innings.openingBowlerId : score.bowlerId,
      activeTwoBowlerIds: const <int>[],
      canUndo: balls.isNotEmpty,
    );
  }

  void selectBowler(int bowlerId) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(selectedBowlerId: bowlerId));
  }

  void selectTwoBowlerPair(List<int> bowlerIds) {
    if (bowlerIds.length != 2 || bowlerIds.toSet().length != 2) {
      throw ArgumentError('Select exactly two different bowlers.');
    }
    final current = state.requireValue;
    state = AsyncData(current.copyWith(
      activeTwoBowlerIds: List<int>.unmodifiable(bowlerIds),
      selectedBowlerId: current.selectedBowlerId ?? bowlerIds.first,
    ));
  }

  void selectFinalOverBowler(int bowlerId) {
    final current = state.requireValue;
    if (!current.innings.twoBowlerMode ||
        current.innings.oversPerInnings.isEven ||
        current.score.completedOvers + 1 != current.innings.oversPerInnings) {
      throw ArgumentError('A single bowler can only be selected for the final odd over.');
    }
    state = AsyncData(current.copyWith(
      activeTwoBowlerIds: List<int>.unmodifiable([bowlerId]),
      selectedBowlerId: bowlerId,
    ));
  }

  Future<void> scoreRuns(int runs) => _apply(DeliveryInput(
        deliveryType: DeliveryType.normal,
        batterRuns: runs,
      ));

  Future<void> scoreWide(int runs) => _apply(DeliveryInput(
        deliveryType: DeliveryType.wide,
        wideRuns: runs,
      ));

  Future<void> scoreNoBall({int batterRuns = 0}) => _apply(DeliveryInput(
        deliveryType: DeliveryType.noBall,
        batterRuns: batterRuns,
        noBallRuns: 1,
      ));

  Future<void> scoreBye(int runs) => _apply(DeliveryInput(
        deliveryType: DeliveryType.bye,
        byeRuns: runs,
      ));

  Future<void> scoreLegBye(int runs) => _apply(DeliveryInput(
        deliveryType: DeliveryType.legBye,
        legByeRuns: runs,
      ));

  Future<void> scoreWicket(Wicket wicket) => scoreWicketDelivery(
        DeliveryInput(
          deliveryType: DeliveryType.normal,
          wicket: wicket,
        ),
      );

  Future<void> scoreWicketDelivery(DeliveryInput input) => _apply(input);

  Future<void> undo() async {
    final current = state.requireValue;
    if (!current.canUndo) return;
    state = const AsyncLoading();
    try {
      final score = await _undoService.undo(inningsId: _inningsId);
      state = AsyncData(current.copyWith(
        score: score,
        selectedBowlerId:
            score.bowlerId == 0 ? current.selectedBowlerId : score.bowlerId,
        canUndo: score.ballCount > 0,
      ));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _apply(DeliveryInput input) async {
    final current = state.requireValue;
    final bowlerId = current.selectedBowlerId;
    if (bowlerId == null || bowlerId <= 0) {
      state = AsyncError(
        StateError('Select a bowler before scoring.'),
        StackTrace.current,
      );
      return;
    }

    try {
      final eligibleBowlerIds = await _eligibleBowlerIds(current.innings);
      state = const AsyncLoading();
      final result = await _applyService.apply(
        inningsId: _inningsId,
        input: input,
        bowlerId: bowlerId,
        eligibleBowlerIds: eligibleBowlerIds,
        activeTwoBowlerIds: current.activeTwoBowlerIds,
      );
      final nextBowler = result.rotation.currentBowlerId;
      state = AsyncData(current.copyWith(
        score: result.state,
        selectedBowlerId: nextBowler == 0 ? null : nextBowler,
        canUndo: true,
      ));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<List<int>> _eligibleBowlerIds(Innings innings) async {
    final players = await ref.read(matchPlayersProvider(innings.matchId).future);
    return players
        .where((player) =>
            player.teamId == innings.bowlingTeamId && player.isPlaying)
        .map((player) => player.playerId)
        .toList(growable: false);
  }

  InningsState _recalculate(Innings innings, List<BallEvent> balls) {
    return const InningsRecalculationEngine().recalculate(
      InningsRecalculationContext(
        balls: balls,
        initialStrikerId: innings.openingStrikerId,
        initialNonStrikerId: innings.openingNonStrikerId,
        initialBowlerId: innings.openingBowlerId,
        ballsPerOver: innings.ballsPerOver,
        totalOvers: innings.oversPerInnings,
      ),
    );
  }
}
