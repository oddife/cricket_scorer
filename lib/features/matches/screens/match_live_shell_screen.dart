import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/sync/sync_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/supabase/supabase_client_provider.dart';
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

class MatchLiveShellScreen extends ConsumerStatefulWidget {
  const MatchLiveShellScreen({super.key, required this.matchId});
  final int matchId;

  @override
  ConsumerState<MatchLiveShellScreen> createState() => _MatchLiveShellScreenState();
}

class _MatchLiveShellScreenState extends ConsumerState<MatchLiveShellScreen> {
  Timer? _syncTimer;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _automaticSync();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _automaticSync() async {
    if (_syncing || !mounted) return;
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    _syncing = true;
    try {
      final worker = ref.read(syncWorkerProvider);
      await worker.runOnce();
      if (!mounted) return;
      ref.read(catalogSyncRefreshProvider.notifier).state++;
      ref.invalidate(teamProvider);
      ref.invalidate(matchProvider);
      ref.invalidate(matchByIdProvider(widget.matchId));
      ref.invalidate(inningsByMatchProvider(widget.matchId));
    } catch (_) {
      // Automatic sync is deliberately silent. The scorer should never be
      // interrupted by a transient network error; Sync Now remains available.
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncNow() async {
    if (_syncing || !mounted) return;
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supabase is not configured.')),
      );
      return;
    }

    setState(() => _syncing = true);
    try {
      final worker = ref.read(syncWorkerProvider);
      await worker.runOnce();
      if (!mounted) return;
      ref.read(catalogSyncRefreshProvider.notifier).state++;
      ref.invalidate(teamProvider);
      ref.invalidate(matchProvider);
      ref.invalidate(matchByIdProvider(widget.matchId));
      ref.invalidate(inningsByMatchProvider(widget.matchId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync complete: ${worker.lastMatchesDownloaded} match(es) pulled, '
            '${worker.lastCatalogDownloaded} catalog item(s) downloaded.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $error'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<_MatchStateData> _matchState(WidgetRef ref, Match match, List<Innings> innings) async {
    final ballsRepository = ref.read(ballEventRepositoryProvider);
    final sorted = [...innings]..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final states = <int, InningsState>{};
    for (final inning in sorted) {
      final balls = await ballsRepository.getForInnings(inning.id);
      states[inning.id] = const InningsRecalculationEngine().recalculate(InningsRecalculationContext(
        balls: balls,
        initialStrikerId: inning.openingStrikerId,
        initialNonStrikerId: inning.openingNonStrikerId,
        initialBowlerId: inning.openingBowlerId,
        ballsPerOver: inning.ballsPerOver,
        totalOvers: inning.oversPerInnings,
      ));
    }
    final result = const MatchResultService().result(match: match, innings: sorted, states: states);
    final current = sorted.isEmpty ? null : sorted.last;
    final currentState = current == null ? null : states[current.id];
    final service = const MatchResultService();
    final target = current == null ? null : service.targetForInnings(match: match, innings: sorted, states: states, inningsNumber: current.inningsNumber);
    final leadDeficit = current == null ? null : service.leadOrDeficitAfterInnings(innings: sorted, states: states, inningsNumber: current.inningsNumber);
    return _MatchStateData(result: result, currentInnings: current, currentState: currentState, target: target, leadDeficit: leadDeficit);
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchByIdProvider(widget.matchId));
    final innings = ref.watch(inningsByMatchProvider(widget.matchId));
    final teams = ref.watch(teamProvider);
    return match.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Unable to load match: $error'))),
      data: (m) {
        if (m == null) return const Scaffold(body: Center(child: Text('Match not found.')));
        return innings.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(body: Center(child: Text('Unable to load innings: $error'))),
          data: (list) => FutureBuilder<_MatchStateData>(
            future: _matchState(ref, m, list),
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
              final result = state.result;
              if (result.completed) {
                return _MatchCompletedView(match: m, result: result, teams: teams.asData?.value ?? const [], matchId: widget.matchId);
              }
              return _LiveMatchView(
                matchId: widget.matchId,
                match: m,
                state: state,
                syncing: _syncing,
                onSync: _syncNow,
              );
            },
          ),
        );
      },
    );
  }
}

class _LiveMatchView extends StatelessWidget {
  const _LiveMatchView({required this.matchId, required this.match, required this.state, required this.syncing, required this.onSync});
  final int matchId;
  final Match match;
  final _MatchStateData state;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final currentInnings = state.currentInnings;
    final situation = currentInnings == null
        ? null
        : _CompactMatchSituation(
            matchInningsCount: match.inningsCount,
            inningsNumber: currentInnings.inningsNumber,
            currentScore: state.currentState?.score ?? 0,
            target: state.target,
            leadDeficit: state.leadDeficit,
          );
    // Keep the controls on the same toolbar line as "Live Scoring" while
    // respecting the Android status-bar inset above the toolbar.
    final topOffset = MediaQuery.paddingOf(context).top + 4;
    return Stack(
      children: [
        MatchLiveScreen(
          matchId: matchId,
          matchSituation: wide ? null : situation,
        ),
        Positioned(
          top: topOffset,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: syncing ? 'Syncing...' : 'Sync Now',
                onPressed: syncing ? null : onSync,
                icon: syncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_outlined),
              ),
              IconButton(
                tooltip: 'Home',
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
              ),
            ],
          ),
        ),
        Positioned(right: 20, bottom: 20, child: FloatingActionButton.extended(heroTag: 'scorecard-$matchId', onPressed: () => context.push('/matches/$matchId/scorecard'), icon: const Icon(Icons.scoreboard_outlined), label: const Text('Scorecard'))),
        if (wide && currentInnings != null)
          Positioned(top: 14, left: 300, right: 300, child: situation!),
      ],
    );
  }
}

class _MatchCompletedView extends StatelessWidget {
  const _MatchCompletedView({required this.match, required this.result, required this.teams, required this.matchId});
  final Match match;
  final MatchResult result;
  final List<Team> teams;
  final int matchId;

  String teamName(int id) => teams.where((team) => team.id == id).firstOrNull?.name ?? 'Team $id';

  String get headline {
    if (result.isTie) return 'MATCH TIED';
    final winner = teamName(result.winnerTeamId!);
    if (result.marginWickets != null) return '$winner WON BY ${result.marginWickets} WICKETS';
    if (result.marginRuns != null) return '$winner WON BY ${result.marginRuns} RUNS';
    return '$winner WON';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Match Completed'), automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  children: [
                    CircleAvatar(radius: 42, backgroundColor: scheme.primaryContainer, child: Icon(Icons.emoji_events, size: 46, color: scheme.onPrimaryContainer)),
                    const SizedBox(height: 22),
                    Text('MATCH COMPLETED', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(match.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Text(headline, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(result.isTie ? 'The match finished level.' : result.marginWickets != null ? '${teamName(result.winnerTeamId!)} finished with ${result.marginWickets} wickets remaining.' : result.marginRuns != null ? '${teamName(result.winnerTeamId!)} won by ${result.marginRuns} runs.' : 'The match has been completed.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => context.push('/matches/$matchId/scorecard'), icon: const Icon(Icons.scoreboard_outlined), label: const Text('View Scorecard'))),
                    const SizedBox(height: 10),
                    MatchPdfExportActions(match: match),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.home_outlined), label: const Text('Go Home'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchStateData {
  const _MatchStateData({required this.result, required this.currentInnings, required this.currentState, required this.target, required this.leadDeficit});
  final MatchResult result;
  final Innings? currentInnings;
  final InningsState? currentState;
  final int? target;
  final int? leadDeficit;
}

class _CompactMatchSituation extends StatelessWidget {
  const _CompactMatchSituation({required this.matchInningsCount, required this.inningsNumber, required this.currentScore, required this.target, required this.leadDeficit});
  final int matchInningsCount;
  final int inningsNumber;
  final int currentScore;
  final int? target;
  final int? leadDeficit;

  @override
  Widget build(BuildContext context) {
    String title;
    String value;
    String detail;
    final targetValue = target;
    final leadDeficitValue = leadDeficit;

    if (matchInningsCount == 2 && inningsNumber == 2 && targetValue != null) {
      final needed = (targetValue - currentScore).clamp(0, targetValue);
      title = 'TARGET';
      value = '$targetValue';
      detail = needed == 0 ? 'Target reached' : 'Need $needed';
    } else if (matchInningsCount == 4 && inningsNumber == 4 && targetValue != null) {
      final needed = (targetValue - currentScore).clamp(0, targetValue);
      title = 'TARGET';
      value = '$targetValue';
      detail = needed == 0 ? 'Target reached' : 'Need $needed';
    } else if (matchInningsCount == 4 && (inningsNumber == 2 || inningsNumber == 3) && leadDeficitValue != null) {
      title = leadDeficitValue >= 0 ? 'LEAD' : 'DEFICIT';
      value = '${leadDeficitValue.abs()}';
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
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(width: 10),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Flexible(child: Text(detail, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
