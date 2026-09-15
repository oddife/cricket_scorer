import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/innings/models/innings.dart';
import '../../../domain/innings/models/innings_recalculation_context.dart';
import '../../../domain/innings/models/innings_state.dart';
import '../../../domain/innings/services/innings_recalculation_engine.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/matches/services/match_result_service.dart';
import '../../../domain/teams/models/team.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/innings_provider.dart';
import '../providers/match_provider.dart';
import 'match_live_screen.dart';

class MatchLiveShellScreen extends ConsumerWidget {
  const MatchLiveShellScreen({super.key, required this.matchId});

  final int matchId;

  Future<_MatchStateData> _matchState(
    WidgetRef ref,
    Match match,
    List<Innings> innings,
  ) async {
    final ballsRepository = ref.read(ballEventRepositoryProvider);
    final sorted = [...innings]
      ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final states = <int, InningsState>{};
    for (final inning in sorted) {
      final balls = await ballsRepository.getForInnings(inning.id);
      states[inning.id] = const InningsRecalculationEngine().recalculate(
        InningsRecalculationContext(
          balls: balls,
          initialStrikerId: inning.openingStrikerId,
          initialNonStrikerId: inning.openingNonStrikerId,
          initialBowlerId: inning.openingBowlerId,
          ballsPerOver: inning.ballsPerOver,
          totalOvers: inning.oversPerInnings,
        ),
      );
    }

    final result = const MatchResultService().result(
      match: match,
      innings: sorted,
      states: states,
    );

    final current = sorted.isEmpty ? null : sorted.last;
    final currentState = current == null ? null : states[current.id];
    final service = const MatchResultService();
    final target = current == null
        ? null
        : service.targetForInnings(
            match: match,
            innings: sorted,
            states: states,
            inningsNumber: current.inningsNumber,
          );
    final leadDeficit = current == null
        ? null
        : service.leadOrDeficitAfterInnings(
            innings: sorted,
            states: states,
            inningsNumber: current.inningsNumber,
          );

    return _MatchStateData(
      result: result,
      currentInnings: current,
      currentState: currentState,
      target: target,
      leadDeficit: leadDeficit,
    );
  }

  String teamName(List<Team> teams, int id) => teams
          .where((team) => team.id == id)
          .firstOrNull
          ?.name ??
      'Team $id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchByIdProvider(matchId));
    final innings = ref.watch(inningsByMatchProvider(matchId));
    final teams = ref.watch(teamProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Stack(
          children: [
            MatchLiveScreen(matchId: matchId),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                heroTag: 'scorecard-$matchId',
                onPressed: () =>
                    context.push('/matches/$matchId/scorecard'),
                icon: const Icon(Icons.scoreboard_outlined),
                label: const Text('Scorecard'),
              ),
            ),
            match.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (m) {
                if (m == null) return const SizedBox.shrink();
                return innings.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (list) {
                    return FutureBuilder<_MatchStateData>(
                      future: _matchState(ref, m, list),
                      builder: (context, snapshot) {
                        final state = snapshot.data;
                        if (state == null) return const SizedBox.shrink();

                        final result = state.result;
                        final showSituation =
                            wide && !result.completed && state.currentInnings != null;

                        return Stack(
                          children: [
                            if (result.completed)
                              Positioned(
                                left: 24,
                                right: 24,
                                top: 70,
                                child: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.emoji_events_outlined),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            result.isTie
                                                ? 'MATCH TIED'
                                                : '${teamName(teams.asData?.value ?? const [], result.winnerTeamId!)} WON${result.marginWickets != null ? ' by ${result.marginWickets} wickets' : result.marginRuns != null ? ' by ${result.marginRuns} runs' : ''}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => context.push(
                                            '/matches/$matchId/scorecard',
                                          ),
                                          child: const Text('View Scorecard'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (showSituation)
                              Positioned(
                                top: 14,
                                left: 300,
                                right: 300,
                                child: _CompactMatchSituation(
                                  matchInningsCount: m.inningsCount,
                                  inningsNumber:
                                      state.currentInnings!.inningsNumber,
                                  currentScore: state.currentState?.score ?? 0,
                                  target: state.target,
                                  leadDeficit: state.leadDeficit,
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _MatchStateData {
  const _MatchStateData({
    required this.result,
    required this.currentInnings,
    required this.currentState,
    required this.target,
    required this.leadDeficit,
  });

  final MatchResult result;
  final Innings? currentInnings;
  final InningsState? currentState;
  final int? target;
  final int? leadDeficit;
}

class _CompactMatchSituation extends StatelessWidget {
  const _CompactMatchSituation({
    required this.matchInningsCount,
    required this.inningsNumber,
    required this.currentScore,
    required this.target,
    required this.leadDeficit,
  });

  final int matchInningsCount;
  final int inningsNumber;
  final int currentScore;
  final int? target;
  final int? leadDeficit;

  @override
  Widget build(BuildContext context) {
    String title;
    String value;
    String? detail;

    if (matchInningsCount == 2 && inningsNumber == 2 && target != null) {
      final needed = (target! - currentScore).clamp(0, target!);
      title = 'TARGET';
      value = '$target';
      detail = needed == 0 ? 'Target reached' : 'Need $needed';
    } else if (matchInningsCount == 4 && inningsNumber == 4 && target != null) {
      final needed = (target! - currentScore).clamp(0, target!);
      title = 'TARGET';
      value = '$target';
      detail = needed == 0 ? 'Target reached' : 'Need $needed';
    } else if (matchInningsCount == 4 &&
        (inningsNumber == 2 || inningsNumber == 3) &&
        leadDeficit != null) {
      title = leadDeficit! >= 0 ? 'LEAD' : 'DEFICIT';
      value = '${leadDeficit!.abs()}';
      detail = 'After innings $inningsNumber';
    } else {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (detail != null) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  detail,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
