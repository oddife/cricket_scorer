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
import '../widgets/match_pdf_export_actions.dart';
import 'match_live_screen.dart';

class MatchLiveShellScreen extends ConsumerWidget {
  const MatchLiveShellScreen({super.key, required this.matchId});
  final int matchId;

  Future<_MatchStateData> _matchState(WidgetRef ref, Match match, List<Innings> innings) async {
    final ballsRepository = ref.read(ballEventRepositoryProvider);
    final engine = ref.read(inningsRecalculationEngineProvider);
    final states = <int, InningsState>{};
    for (final inning in innings) {
      final events = await ballsRepository.getForInnings(inning.id);
      final context = InningsRecalculationContext(
        innings: inning,
        balls: events,
        initialStrikerId: inning.strikerId,
        initialNonStrikerId: inning.nonStrikerId,
        initialBowlerId: inning.bowlerId,
        ballsPerOver: match.ballsPerOver,
        totalOvers: inning.totalOvers,
        maxWickets: match.playersPerTeam - 1,
        target: inning.target,
      );
      states[inning.id] = engine.recalculate(context);
    }
    final result = ref.read(matchResultServiceProvider).result(
      match: match,
      innings: innings,
      states: states,
    );
    return _MatchStateData(states: states, result: result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchByIdProvider(matchId));
    final inningsAsync = ref.watch(inningsForMatchProvider(matchId));
    return matchAsync.when(
      data: (match) {
        if (match == null) {
          return const Scaffold(body: Center(child: Text('Match not found')));
        }
        return inningsAsync.when(
          data: (innings) => FutureBuilder<_MatchStateData>(
            future: _matchState(ref, match, innings),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final data = snapshot.data!;
              if (data.result.isComplete) {
                return _MatchCompletedView(matchId: matchId, match: match, innings: innings, data: data);
              }
              return MatchLiveScreen(matchId: matchId);
            },
          ),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}

class _MatchCompletedView extends StatelessWidget {
  const _MatchCompletedView({required this.matchId, required this.match, required this.innings, required this.data});
  final int matchId;
  final Match match;
  final List<Innings> innings;
  final _MatchStateData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Completed')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.result.summary, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Match #$matchId'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MatchPdfExportActions(match: match),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push('/matches/$matchId/scorecard'),
            icon: const Icon(Icons.scoreboard),
            label: const Text('View Final Scorecard'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/matches/$matchId'),
            child: const Text('Back to Match'),
          ),
          const SizedBox(height: 16),
          for (final inning in innings) _InningsSummaryCard(innings: inning, state: data.states[inning.id]),
        ],
      ),
    );
  }
}

class _InningsSummaryCard extends StatelessWidget {
  const _InningsSummaryCard({required this.innings, required this.state});
  final Innings innings;
  final InningsState? state;

  @override
  Widget build(BuildContext context) {
    final score = state?.score ?? 0;
    final wickets = state?.wickets ?? 0;
    final overs = state == null ? '0.0' : '${state!.completedOvers}.${state!.legalBallsInCurrentOver}';
    return Card(
      child: ListTile(
        title: Text('Innings ${innings.inningsNumber}'),
        subtitle: Text('$score/$wickets in $overs overs'),
      ),
    );
  }
}

class _MatchStateData {
  const _MatchStateData({required this.states, required this.result});
  final Map<int, InningsState> states;
  final MatchResult result;
}
