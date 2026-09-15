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
import '../../../domain/players/models/player.dart';
import '../../../domain/teams/models/team.dart';
import '../../players/providers/player_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/innings_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/match_pdf_export_actions.dart';

class MatchScorecardScreen extends ConsumerWidget {
  const MatchScorecardScreen({super.key, required this.matchId});
  final int matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchByIdProvider(matchId));
    final innings = ref.watch(inningsByMatchProvider(matchId));
    final teams = ref.watch(teamProvider);
    final players = ref.watch(playerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scorecard'),
        leading: IconButton(
          tooltip: 'Back', icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/matches/$matchId/live'),
        ),
      ),
      body: match.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load match: $e')),
        data: (m) {
          if (m == null) return const Center(child: Text('Match not found.'));
          return innings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Unable to load innings: $e')),
            data: (list) => teams.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Unable to load teams: $e')),
              data: (teamList) => players.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Unable to load players: $e')),
                data: (playerList) => _ScorecardBody(match: m, innings: list, teams: teamList, players: playerList),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScorecardBody extends ConsumerWidget {
  const _ScorecardBody({required this.match, required this.innings, required this.teams, required this.players});
  final Match match;
  final List<Innings> innings;
  final List<Team> teams;
  final List<Player> players;

  String teamName(int id) => teams.where((team) => team.id == id).firstOrNull?.name ?? 'Team $id';
  String playerName(int id) => players.where((player) => player.id == id).firstOrNull?.displayName ?? 'Player $id';

  Future<_ScorecardData> _load(WidgetRef ref) async {
    final ballRepository = ref.read(ballEventRepositoryProvider);
    final sorted = [...innings]..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final states = <int, InningsState>{};
    final service = const MatchResultService();
    final rows = <_InningsRow>[];
    for (final inning in sorted) {
      final balls = await ballRepository.getForInnings(inning.id);
      final target = service.targetForInnings(match: match, innings: sorted, states: states, inningsNumber: inning.inningsNumber);
      final state = const InningsRecalculationEngine().recalculate(InningsRecalculationContext(
        balls: balls,
        initialStrikerId: inning.openingStrikerId,
        initialNonStrikerId: inning.openingNonStrikerId,
        initialBowlerId: inning.openingBowlerId,
        ballsPerOver: inning.ballsPerOver,
        totalOvers: inning.oversPerInnings,
        target: target,
      ));
      states[inning.id] = state;
      rows.add(_InningsRow(innings: inning, state: state, target: target));
    }
    return _ScorecardData(rows: rows, result: service.result(match: match, innings: sorted, states: states));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_ScorecardData>(
      future: _load(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Unable to build scorecard: ${snapshot.error}'));
        final data = snapshot.data!;
        final rows = data.rows;
        final result = data.result;
        final complete = result.completed;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(match.name, style: Theme.of(context).textTheme.headlineSmall),
                if (complete) ...[
                  const SizedBox(height: 12),
                  Card(child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: result.isTie
                        ? const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MATCH TIED', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Both teams finished with the same aggregate score.')])
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('MATCH COMPLETE', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('${teamName(result.winnerTeamId!)} won', style: Theme.of(context).textTheme.headlineSmall),
                            if (result.marginRuns != null) Text('By ${result.marginRuns} runs'),
                          ]),
                  )),
                ],
                const SizedBox(height: 12),
                MatchPdfExportActions(match: match),
                const SizedBox(height: 16),
                for (final row in rows) _InningsCard(row: row, teamName: teamName(row.innings.battingTeamId), playerName: playerName, previousRows: rows),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _ScorecardData { const _ScorecardData({required this.rows, required this.result}); final List<_InningsRow> rows; final MatchResult result; }
class _InningsRow { const _InningsRow({required this.innings, required this.state, this.target}); final Innings innings; final InningsState state; final int? target; }

class _InningsCard extends StatelessWidget {
  const _InningsCard({required this.row, required this.teamName, required this.playerName, required this.previousRows});
  final _InningsRow row; final String teamName; final String Function(int) playerName; final List<_InningsRow> previousRows;

  String _leadDeficit() {
    if (row.innings.inningsNumber < 2) return '';
    final totals = <int, int>{};
    for (final previous in previousRows) {
      if (previous.innings.inningsNumber > row.innings.inningsNumber) continue;
      totals[previous.innings.battingTeamId] = (totals[previous.innings.battingTeamId] ?? 0) + previous.state.score;
    }
    final currentTotal = totals[row.innings.battingTeamId] ?? 0;
    final opponents = totals.keys.where((id) => id != row.innings.battingTeamId);
    if (opponents.isEmpty) return '';
    final opponentTotal = totals[opponents.first] ?? 0;
    final difference = currentTotal - opponentTotal;
    if (difference == 0) return 'Scores level';
    return difference > 0 ? '$teamName lead by $difference' : '$teamName trail by ${difference.abs()}';
  }

  @override
  Widget build(BuildContext context) {
    final state = row.state;
    final overs = '${state.completedOvers}.${state.legalBallsInCurrentOver}';
    final leadDeficit = _leadDeficit();
    final showTarget = row.target != null;
    final batters = state.batters.values.toList()..sort((a, b) => a.playerId.compareTo(b.playerId));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('Innings ${row.innings.inningsNumber} • $teamName', style: Theme.of(context).textTheme.titleLarge)),
            Text('${state.score}/${state.wickets}', style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 4), Text('$overs overs'),
          if (showTarget) ...[
            const SizedBox(height: 8), Text('TARGET ${row.target}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (state.score < row.target!) Text('Need ${row.target! - state.score} more'),
            if (state.score >= row.target!) const Text('Target reached'),
          ],
          if (leadDeficit.isNotEmpty) ...[const SizedBox(height: 8), Text(leadDeficit, style: const TextStyle(fontWeight: FontWeight.bold))],
          if (batters.isNotEmpty) ...[
            const Divider(height: 24),
            const Row(children: [Expanded(child: Text('BATTER')), SizedBox(width: 55, child: Text('R')), SizedBox(width: 55, child: Text('B')), SizedBox(width: 55, child: Text('4s')), SizedBox(width: 55, child: Text('6s'))]),
            const SizedBox(height: 6),
            for (final batter in batters) Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(child: Text('${playerName(batter.playerId)}${batter.isOut ? '' : '*'}')),
                SizedBox(width: 55, child: Text('${batter.runs}')),
                SizedBox(width: 55, child: Text('${batter.balls}')),
                SizedBox(width: 55, child: Text('${batter.fours}')),
                SizedBox(width: 55, child: Text('${batter.sixes}')),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
