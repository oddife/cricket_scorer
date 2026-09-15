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

  Future<MatchResult> _result(
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
    return const MatchResultService().result(
      match: match,
      innings: sorted,
      states: states,
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

    return Stack(
      children: [
        MatchLiveScreen(matchId: matchId),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'scorecard-$matchId',
            onPressed: () => context.push('/matches/$matchId/scorecard'),
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
                return FutureBuilder<MatchResult>(
                  future: _result(ref, m, list),
                  builder: (context, snapshot) {
                    final result = snapshot.data;
                    if (result == null || !result.completed) {
                      return const SizedBox.shrink();
                    }
                    final message = result.isTie
                        ? 'MATCH TIED'
                        : '${teamName(teams.asData?.value ?? const [], result.winnerTeamId!)} WON';
                    final detail = result.marginWickets != null
                        ? 'by ${result.marginWickets} wickets'
                        : result.marginRuns != null
                            ? 'by ${result.marginRuns} runs'
                            : '';
                    return Positioned(
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
                                  detail.isEmpty ? message : '$message $detail',
                                  style: Theme.of(context).textTheme.titleMedium,
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
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
