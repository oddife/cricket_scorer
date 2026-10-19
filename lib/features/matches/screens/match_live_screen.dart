import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/management/permanent_delete_service.dart';
import '../../../application/sync/sync_provider.dart';

import '../../../domain/innings/enums/innings_status.dart';
import '../../../domain/players/models/player.dart';
import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/models/ball_event.dart';
import '../../../domain/scoring/models/delivery_input.dart';
import '../../../domain/scoring/services/wicket_workflow_service.dart';
import '../../players/providers/player_provider.dart';
import '../../players/widgets/add_player_dialog.dart';
import '../providers/innings_provider.dart';
import '../providers/live_scoring_provider.dart';
import '../providers/man_of_match_suggestion_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/ball_by_ball_card.dart';
import '../widgets/bowler_colour_coding.dart';
import '../widgets/delivery_aware_wicket_dialog.dart';

class MatchLiveScreen extends ConsumerWidget {
  const MatchLiveScreen({super.key, required this.matchId, this.matchSituation});

  final int matchId;
  final Widget? matchSituation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchByIdProvider(matchId));
    final innings = ref.watch(inningsByMatchProvider(matchId));
    final players = ref.watch(matchPlayersProvider(matchId));
    final names = ref.watch(playerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scoring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/matches/$matchId'),
        ),
      ),
      body: match.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load match: $e')),
        data: (m) {
          if (m == null) {
            return const Center(child: Text('Match not found.'));
          }
          return innings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Unable to load innings: $e')),
            data: (list) {
              if (list.isEmpty) {
                return _UnstartedMatchView(
                  matchId: matchId,
                  matchName: m.name,
                  tournamentId: m.tournamentId,
                );
              }
              final sorted = List.of(list)
                ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
              return players.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Unable to load players: $e')),
                data: (matchPlayers) => names.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Unable to load player names: $e')),
                  data: (globalPlayers) => _ScoringView(
                    matchName: m.name,
                    matchId: matchId,
                    matchInningsCount: m.inningsCount,
                    bowlerColoursEnabled:
                        m.twoBowlerMode && m.bowlerColourCodingEnabled,
                    inningsId: sorted.last.id,
                    matchPlayers: matchPlayers,
                    globalPlayers: globalPlayers,
                    matchSituation: matchSituation,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UnstartedMatchView extends ConsumerWidget {
  const _UnstartedMatchView({
    required this.matchId,
    required this.matchName,
    required this.tournamentId,
  });

  final int matchId;
  final String matchName;
  final int? tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.sports_cricket_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    matchName,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The first innings has not been set up yet.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.go('/matches/$matchId/opening'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Set Up First Innings'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _deleteMatch(context, ref),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Unstarted Match'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMatch(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete unstarted match?'),
        content: Text(
          'Permanently delete "$matchName"? This removes only the match and its scoring data, not the tournament, teams, or tournament points rules.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Match'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(permanentDeleteServiceProvider).deleteMatch(matchId);
      ref.invalidate(matchProvider);
      ref.invalidate(matchByIdProvider(matchId));
      ref.invalidate(matchTeamsProvider(matchId));
      ref.invalidate(matchPlayersProvider(matchId));
      ref.invalidate(inningsByMatchProvider(matchId));
      if (context.mounted) {
        context.go(
          tournamentId == null
              ? '/matches/live'
              : '/tournaments/$tournamentId',
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete match: $error')),
      );
    }
  }
}

class _ScoringView extends ConsumerWidget {
  const _ScoringView({
    required this.matchName,
    required this.matchId,
    required this.matchInningsCount,
    required this.bowlerColoursEnabled,
    required this.inningsId,
    required this.matchPlayers,
    required this.globalPlayers,
    this.matchSituation,
  });

  final String matchName;
  final int matchId;
  final int matchInningsCount;
  final bool bowlerColoursEnabled;
  final int inningsId;
  final List matchPlayers;
  final List<Player> globalPlayers;
  final Widget? matchSituation;

  String name(int id) =>
      globalPlayers.where((p) => p.id == id).firstOrNull?.displayName ??
      'Player $id';

  String colourIdentity(int id) {
    final player = globalPlayers.where((p) => p.id == id).firstOrNull;
    final syncId = player?.syncId?.trim();
    if (syncId != null && syncId.isNotEmpty) return 'sync:$syncId';
    final stableName = (player?.displayName ?? name(id)).trim().toLowerCase();
    return 'name:$stableName';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveScoringProvider(inningsId));
    final ballEvents = ref.watch(ballEventsByInningsProvider(inningsId));
    final balls = ballEvents.asData?.value ?? const <BallEvent>[];

    ref.listen<int>(syncDataRefreshProvider, (previous, next) {
      if (previous != null && previous != next) {
        unawaited(
          ref.read(liveScoringProvider(inningsId).notifier).refreshFromDatabase(),
        );
      }
    });

    ref.listen<AsyncValue<LiveScoringState>>(
      liveScoringProvider(inningsId),
      (previous, next) {
        final nextState = next.asData?.value;
        final wasComplete =
            previous?.asData?.value.score.inningsComplete ?? false;
        if (nextState == null ||
            !nextState.score.inningsComplete ||
            wasComplete ||
            nextState.innings.inningsNumber >= matchInningsCount) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/matches/$matchId/opening');
          }
        });
      },
    );

    return live.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Unable to load scoring state: $e')),
      data: (data) {
        final s = data.score;
        final showBowlerColours =
            data.innings.twoBowlerMode && bowlerColoursEnabled;
        final bowlerColourIdentities = <int, String>{
          for (final player in globalPlayers)
            player.id: colourIdentity(player.id),
        };
        // Historical deliveries can refer to players no longer in the active
        // global-player list. Keep a stable name-based fallback for those IDs.
        for (final ball in balls) {
          bowlerColourIdentities.putIfAbsent(
            ball.bowlerId,
            () => colourIdentity(ball.bowlerId),
          );
        }
        final inningsClosed = s.inningsComplete ||
            data.innings.status == InningsStatus.ended ||
            data.innings.status == InningsStatus.completed;
        final strikerId = data.liveStrikerId;
        final nonStrikerId = data.liveNonStrikerId;
        final striker = s.batters[strikerId];
        final nonStriker = s.batters[nonStrikerId];
        final bowlerId = data.selectedBowlerId ?? s.bowlerId;
        final bowler = s.bowlers[bowlerId];
        final currentOverNumber = balls.isEmpty ? 0 : balls.last.overNumber;

        final bowlers = matchPlayers
            .where(
              (p) =>
                  p.teamId == data.innings.bowlingTeamId && p.isPlaying,
            )
            .map((p) => p.playerId as int)
            .toList();
        final battingPlayers = matchPlayers
            .where(
              (p) =>
                  p.teamId == data.innings.battingTeamId && p.isPlaying,
            )
            .map((p) => p.playerId as int)
            .toList();
        final unused = battingPlayers
            .where((id) => !s.batters.containsKey(id))
            .toList();

        final finalOddOver =
            data.innings.twoBowlerMode &&
            data.innings.oversPerInnings.isOdd &&
            s.completedOvers + 1 == data.innings.oversPerInnings;
        // In the single-bowler final over, neither bowler from the previous
        // two-over block is eligible. Keep these names visible but disabled.
        final finalOverPreviousPair = finalOddOver
            ? balls
                .where(
                  (ball) =>
                      ball.overNumber >= data.innings.oversPerInnings - 2 &&
                      ball.overNumber < data.innings.oversPerInnings,
                )
                .map((ball) => ball.bowlerId)
                .toSet()
            : const <int>{};
        final enabled =
            !s.inningsComplete &&
            !s.requiresBatterReplacement &&
            data.selectedBowlerId != null &&
            (!data.innings.twoBowlerMode ||
                (finalOddOver
                    ? data.activeTwoBowlerIds.length == 1
                    : data.activeTwoBowlerIds.length == 2));

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final batterCard = Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Batters'),
                    trailing: OutlinedButton.icon(
                      onPressed: s.inningsComplete
                          ? null
                          : () => _manageBatters(
                                context,
                                ref,
                                data,
                                battingPlayers,
                                allowOpeningSelection: balls.isEmpty,
                              ),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Manage'),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: s.inningsComplete
                          ? null
                          : () => _addPlayerToMatch(
                                context,
                                ref,
                                teamId: data.innings.battingTeamId,
                                teamLabel: 'batting team',
                              ),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Player'),
                    ),
                  ),
                  ListTile(
                    leading: const Text('▶'),
                    title: Text(name(strikerId)),
                    trailing: Text(
                      '${striker?.runs ?? 0}  ${striker?.balls ?? 0}',
                    ),
                  ),
                  ListTile(
                    title: Text(name(nonStrikerId)),
                    trailing: Text(
                      '${nonStriker?.runs ?? 0}  ${nonStriker?.balls ?? 0}',
                    ),
                  ),
                ],
              ),
            );

            final bowlerCard = Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.sports_baseball),
                    title: BowlerNameOutline(
                      enabled: showBowlerColours,
                      playerIdentity:
                          bowlerId == 0 ? '' : colourIdentity(bowlerId),
                      child: Text(
                        bowlerId == 0 ? 'Select bowler' : name(bowlerId),
                      ),
                    ),
                    subtitle: Text(
                      'Overs ${bowler == null ? '0.0' : '${bowler.legalBalls ~/ s.ballsPerOver}.${bowler.legalBalls % s.ballsPerOver}'} '
                      '• Runs ${bowler?.runsConceded ?? 0} '
                      '• Wickets ${bowler?.wickets ?? 0}',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      child: TextButton.icon(
                        onPressed: s.inningsComplete
                            ? null
                            : () => _addPlayerToMatch(
                                  context,
                                  ref,
                                  teamId: data.innings.bowlingTeamId,
                                  teamLabel: 'bowling team',
                                ),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add Bowler'),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final pinnedHeader = Column(
              children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      matchName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      'Innings ${data.innings.inningsNumber}',
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${s.score}/${s.wickets}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${s.completedOvers}.${s.legalBallsInCurrentOver} ov '
                                    '• CRR ${s.legalBalls == 0 ? '0.00' : (s.score / (s.legalBalls / s.ballsPerOver)).toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!wide && matchSituation != null) ...[
                        const SizedBox(height: 12),
                        matchSituation!,
                      ],
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: pinnedHeader,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (s.requiresBatterReplacement && !s.inningsComplete)
                        Card(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Batter replacement required',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Select the new batter before the next delivery.',
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Replacement batter',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: unused
                                      .map(
                                        (id) => DropdownMenuItem(
                                          value: id,
                                          child: Text(name(id)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      _action(
                                        context,
                                        ref,
                                        () => ref
                                            .read(liveScoringProvider(inningsId)
                                                .notifier)
                                            .selectReplacementBatter(id),
                                      );
                                    }
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _addPlayerToMatch(
                                      context,
                                      ref,
                                      teamId: data.innings.battingTeamId,
                                      teamLabel: 'batting team',
                                    ),
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('Add a player'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (inningsClosed)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Innings ${data.innings.inningsNumber} complete',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${s.score}/${s.wickets} in ${s.completedOvers}.${s.legalBallsInCurrentOver} overs',
                                ),
                                if (data.innings.inningsNumber <
                                    matchInningsCount) ...[
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => context.go(
                                      '/matches/$matchId/opening',
                                    ),
                                    icon: const Icon(Icons.arrow_forward),
                                    label: Text(
                                      'Set Up Innings ${data.innings.inningsNumber + 1}',
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 16),
                                  const Text('Match innings are complete.'),
                                  const SizedBox(height: 12),
                                  _ManOfTheMatchSuggestion(
                                    matchId: matchId,
                                    playerName: name,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: batterCard),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: bowlerCard),
                          ],
                        )
                      else ...[
                        batterCard,
                        const SizedBox(height: 12),
                        bowlerCard,
                      ],
                      const SizedBox(height: 12),
                      BallByBallCard(
                        balls: balls,
                        currentOverNumber: currentOverNumber,
                        ballsPerOver: s.ballsPerOver,
                        bowlerColourIdentities: bowlerColourIdentities,
                        showBowlerColours: showBowlerColours,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Current over: ${s.legalBallsInCurrentOver} / ${s.ballsPerOver}\n'
                            'Extras: WD ${s.wides}  NB ${s.noBalls}  B ${s.byes}  LB ${s.legByes}',
                          ),
                        ),
                      ),
                      if (!s.inningsComplete) ...[
                        const SizedBox(height: 12),
                        if (!data.innings.twoBowlerMode)
                          _BowlerSelector(
                            selected: data.selectedBowlerId,
                            bowlers: bowlers,
                            name: name,
                            colourIdentity: colourIdentity,
                            showBowlerColours: showBowlerColours,
                            onChanged: (id) => ref
                                .read(liveScoringProvider(inningsId).notifier)
                                .selectBowler(id),
                          )
                        else if (finalOddOver)
                          _BowlerSelector(
                            selected: finalOverPreviousPair
                                    .contains(data.selectedBowlerId)
                                ? null
                                : data.selectedBowlerId,
                            bowlers: bowlers,
                            disabledBowlerIds: finalOverPreviousPair,
                            name: name,
                            colourIdentity: colourIdentity,
                            showBowlerColours: showBowlerColours,
                            label: 'Final over bowler (previous pair rests)',
                            onChanged: (id) => ref
                                .read(liveScoringProvider(inningsId).notifier)
                                .selectFinalOverBowler(id),
                          )
                        else
                          _PairSelector(
                            ids: data.activeTwoBowlerIds,
                            selected: data.selectedBowlerId,
                            name: name,
                            colourIdentity: colourIdentity,
                            showBowlerColours: showBowlerColours,
                            onSelect: () =>
                                _pairDialog(context, ref, data, bowlers),
                          ),
                        const SizedBox(height: 12),
                        _ScoringPad(
                          enabled: enabled,
                          onRuns: (runs) => _action(
                            context,
                            ref,
                            () => ref
                                .read(liveScoringProvider(inningsId).notifier)
                                .scoreRuns(runs),
                          ),
                          onWide: () => _deliveryDialog(
                            context,
                            ref,
                            data,
                            matchPlayers,
                            DeliveryType.wide,
                          ),
                          onNoBall: () => _deliveryDialog(
                            context,
                            ref,
                            data,
                            matchPlayers,
                            DeliveryType.noBall,
                          ),
                          onBye: () => _deliveryDialog(
                            context,
                            ref,
                            data,
                            matchPlayers,
                            DeliveryType.bye,
                          ),
                          onLegBye: () => _deliveryDialog(
                            context,
                            ref,
                            data,
                            matchPlayers,
                            DeliveryType.legBye,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: enabled
                              ? () => _deliveryDialog(
                                    context,
                                    ref,
                                    data,
                                    matchPlayers,
                                    DeliveryType.normal,
                                  )
                              : null,
                          icon: const Icon(Icons.sports_cricket),
                          label: const Text('Wicket'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: () => _endInnings(context, ref, data),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('End Innings'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: data.canUndo
                            ? () => ref
                                .read(liveScoringProvider(inningsId).notifier)
                                .undo()
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
          },
        );
      },
    );
  }

  Future<void> _endInnings(
    BuildContext context,
    WidgetRef ref,
    LiveScoringState data,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Innings?'),
        content: const Text(
          'This will stop scoring for the current innings. The score will be kept and you can continue with the next innings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Innings'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await _action(
      context,
      ref,
      () async {
        await ref
            .read(liveScoringProvider(inningsId).notifier)
            .endInnings();
        if (!context.mounted) return;
        if (data.innings.inningsNumber < matchInningsCount) {
          context.go('/matches/$matchId/opening');
        } else {
          context.go('/matches/$matchId/live');
        }
      },
    );
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _deliveryDialog(
    BuildContext context,
    WidgetRef ref,
    LiveScoringState data,
    List players,
    DeliveryType deliveryType,
  ) async {
    final fielders = players
        .where(
          (p) => p.teamId == data.innings.bowlingTeamId && p.isPlaying,
        )
        .map((p) => p.playerId as int)
        .toList();
    final batting = players
        .where(
          (p) => p.teamId == data.innings.battingTeamId && p.isPlaying,
        )
        .map((p) => p.playerId as int)
        .toList();
    final replacements = batting
        .where((id) => !data.score.batters.containsKey(id))
        .toList();

    final result = await DeliveryAwareWicketDialog.show(
      context: context,
      name: name,
      strikerId: data.liveStrikerId,
      nonStrikerId: data.liveNonStrikerId,
      fielders: fielders,
      replacements: replacements,
      initialDeliveryType: deliveryType,
    );
    if (result == null || !context.mounted) return;

    try {
      final wicketInput = result.wicketInput;
      final wicket = wicketInput == null
          ? null
          : const WicketWorkflowService().create(
              input: wicketInput,
              strikerId: data.liveStrikerId,
              nonStrikerId: data.liveNonStrikerId,
              deliveryType: wicketInput.deliveryType,
              eligibleFielderIds: fielders.toSet(),
            );

      await ref
          .read(liveScoringProvider(inningsId).notifier)
          .scoreWicketDelivery(
            DeliveryInput(
              deliveryType: result.delivery.deliveryType,
              batterRuns: result.delivery.batterRuns,
              byeRuns: result.delivery.byeRuns,
              legByeRuns: result.delivery.legByeRuns,
              wideRuns: result.delivery.wideRuns,
              noBallRuns: result.delivery.noBallRuns,
              wicket: wicket,
            ),
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _addPlayerToMatch(
    BuildContext context,
    WidgetRef ref, {
    required int teamId,
    required String teamLabel,
  }) async {
    try {
      final match = await ref.read(matchByIdProvider(matchId).future);
      if (match == null) throw StateError('Match not found.');

      final currentPlayers =
          await ref.read(matchPlayersProvider(matchId).future);
      final teamCount =
          currentPlayers.where((player) => player.teamId == teamId).length;
      if (teamCount >= match.playersPerTeam) {
        throw StateError(
          'This team has reached the configured limit of ${match.playersPerTeam} players.',
        );
      }

      final currentIds =
          currentPlayers.map((player) => player.playerId).toSet();
      final candidates = (await ref.read(playerProvider.future))
          .where((player) => !currentIds.contains(player.id))
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

      if (!context.mounted) return;

      var query = '';
      final scrollController = ScrollController();
      Player? selectedPlayer;
      // The provider reads above can cross async gaps; do not open a dialog
      // with a context whose scoring screen has already been disposed.
      if (!context.mounted) return;
      try {
        selectedPlayer = await showDialog<Player>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              final normalizedQuery = query.trim().toLowerCase();
              final filtered = candidates.where((player) {
                if (normalizedQuery.isEmpty) return true;
                return player.displayName.toLowerCase().contains(normalizedQuery) ||
                    player.name.toLowerCase().contains(normalizedQuery) ||
                    (player.jerseyNumber?.toString().contains(normalizedQuery) ??
                        false);
              }).toList();
              final screenHeight = MediaQuery.sizeOf(context).height;
              final listHeight =
                  (screenHeight * 0.50).clamp(180.0, 400.0).toDouble();

              return AlertDialog(
                title: Text('Add player to $teamLabel'),
                content: SizedBox(
                  width: 520,
                  height: listHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choose an existing player or create a new player. '
                        'The player will be available to this team immediately.',
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        autofocus: false,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Search players',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            setDialogState(() => query = value),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: candidates.isEmpty
                            ? const Center(
                                child: Text(
                                  'All existing players are already in this match. '
                                  'Create a new player to continue.',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : filtered.isEmpty
                                ? const Center(
                                    child: Text('No players match your search.'),
                                  )
                                : Scrollbar(
                                    controller: scrollController,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      controller: scrollController,
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final player = filtered[index];
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.person_outline,
                                          ),
                                          title: Text(player.displayName),
                                          subtitle: player.jerseyNumber == null
                                              ? null
                                              : Text(
                                                  'Jersey #${player.jerseyNumber}',
                                                ),
                                          onTap: () => Navigator.pop(
                                            dialogContext,
                                            player,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final created = await showAddPlayerDialog(context, ref);
                      if (created != null && dialogContext.mounted) {
                        Navigator.pop(dialogContext, created);
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Create New'),
                  ),
                ],
              );
            },
          ),
        );
      } finally {
        scrollController.dispose();
      }

      if (selectedPlayer == null || !context.mounted) return;

      await ref.read(matchProvider.notifier).addAvailablePlayerToMatch(
            matchId: matchId,
            teamId: teamId,
            playerId: selectedPlayer.id,
          );
      // addAvailablePlayerToMatch invalidates the match-player provider, and
      // the create-player dialog refreshes the global player provider itself.
      await ref.read(matchPlayersProvider(matchId).future);

      if (!context.mounted) return;
      final message = teamLabel == 'batting team'
          ? 'Added ${selectedPlayer.displayName} to the batting team. They will be available when a batter replacement is required.'
          : 'Added ${selectedPlayer.displayName} to the bowling team. They are available in the bowler selector.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _manageBatters(
    BuildContext context,
    WidgetRef ref,
    LiveScoringState data,
    List<int> players, {
    required bool allowOpeningSelection,
  }) async {
    var striker = data.liveStrikerId;
    var nonStriker = data.liveNonStrikerId;

    final result = await showDialog<(int, int)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Manage Batters'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: striker,
                decoration: const InputDecoration(
                  labelText: 'Striker',
                  border: OutlineInputBorder(),
                ),
                items: players
                    .where(
                      (id) =>
                          (allowOpeningSelection ||
                              data.score.batters.containsKey(id)) &&
                          id != nonStriker &&
                          data.score.batters[id]?.isOut != true,
                    )
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(name(id)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => striker = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: nonStriker,
                decoration: const InputDecoration(
                  labelText: 'Non-striker',
                  border: OutlineInputBorder(),
                ),
                items: players
                    .where(
                      (id) =>
                          (allowOpeningSelection ||
                              data.score.batters.containsKey(id)) &&
                          id != striker &&
                          data.score.batters[id]?.isOut != true,
                    )
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(name(id)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => nonStriker = value);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    final temp = striker;
                    striker = nonStriker;
                    nonStriker = temp;
                  });
                },
                icon: const Icon(Icons.swap_vert),
                label: const Text('Swap striker / non-striker'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (striker, nonStriker)),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      await _action(
        context,
        ref,
        () => ref.read(liveScoringProvider(inningsId).notifier).selectBatters(
              strikerId: result.$1,
              nonStrikerId: result.$2,
            ),
      );
    }
  }

  Future<void> _pairDialog(
    BuildContext context,
    WidgetRef ref,
    LiveScoringState data,
    List<int> bowlers,
  ) async {
    final balls = ref.read(ballEventsByInningsProvider(inningsId)).value ??
        const <BallEvent>[];
    final blockBoundary = data.score.legalBallsInCurrentOver == 0 &&
        data.score.completedOvers > 0 &&
        data.score.completedOvers.isEven;
    final previousOverBowlers = blockBoundary
        ? balls
            .where((b) => b.overNumber == data.score.completedOvers)
            .map((b) => b.bowlerId)
            .toSet()
        : <int>{};

    final selected = <int>{...data.activeTwoBowlerIds}
      ..removeAll(previousOverBowlers);
    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Select two bowlers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (blockBoundary && previousOverBowlers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'New pair required: bowlers from over '
                    '${data.score.completedOvers} must rest. They cannot bowl '
                    'overs ${data.score.completedOvers + 1}-'
                    '${data.score.completedOvers + 2}.',
                  ),
                ),
              ...bowlers.map(
                (id) => CheckboxListTile(
                  value: selected.contains(id),
                  title: BowlerNameOutline(
                    enabled: bowlerColoursEnabled && data.innings.twoBowlerMode,
                    playerIdentity: colourIdentity(id),
                    child: Text(name(id)),
                  ),
                  onChanged: previousOverBowlers.contains(id)
                      ? null
                      : (value) {
                          setState(() {
                            if (value == true && selected.length < 2) {
                              selected.add(id);
                            } else if (value != true) {
                              selected.remove(id);
                            }
                          });
                        },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.length == 2
                  ? () => Navigator.pop(ctx, selected.toList())
                  : null,
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      await _action(
        context,
        ref,
        () async => ref
            .read(liveScoringProvider(inningsId).notifier)
            .selectTwoBowlerPair(result),
      );
    }
  }
}

class _ManOfTheMatchSuggestion extends ConsumerWidget {
  const _ManOfTheMatchSuggestion({
    required this.matchId,
    required this.playerName,
  });

  final int matchId;
  final String Function(int) playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(manOfMatchSuggestionProvider(matchId));
    return suggestion.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Calculating Man of the Match suggestion…')),
            ],
          ),
        ),
      ),
      error: (error, _) => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Man of the Match suggestion is unavailable. Check the scorecard.'),
        ),
      ),
      data: (candidate) {
        if (candidate == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No player contribution is recorded yet, so a suggestion is not available.',
              ),
            ),
          );
        }
        final details = <String>[
          'Batting ${candidate.runs} runs off ${candidate.ballsFaced} balls',
          if (candidate.wickets > 0 || candidate.runsConceded > 0)
            'Bowling ${candidate.wickets} wickets • ${candidate.runsConceded} runs conceded',
          if (candidate.fieldingDismissals > 0)
            'Fielding dismissals ${candidate.fieldingDismissals}',
        ].join(' • ');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Suggested Man of the Match',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  playerName(candidate.playerId),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(details),
                const SizedBox(height: 8),
                Text(
                  'Suggestion based on recorded batting runs, wickets and fielding dismissals. You make the final decision.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BowlerSelector extends StatelessWidget {
  const _BowlerSelector({
    required this.selected,
    required this.bowlers,
    required this.name,
    required this.onChanged,
    this.disabledBowlerIds = const <int>{},
    this.label = 'Current bowler',
    required this.colourIdentity,
    this.showBowlerColours = false,
  });

  final int? selected;
  final List<int> bowlers;
  final String Function(int) name;
  final ValueChanged<int> onChanged;
  final Set<int> disabledBowlerIds;
  final String label;
  final String Function(int) colourIdentity;
  final bool showBowlerColours;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<int>(
          initialValue: selected,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: bowlers
              .map(
                (id) {
                  final disabled = disabledBowlerIds.contains(id);
                  return DropdownMenuItem<int>(
                    value: id,
                    enabled: !disabled,
                    child: BowlerNameOutline(
                      enabled: showBowlerColours,
                      playerIdentity: colourIdentity(id),
                      child: Text(
                        name(id),
                        style: disabled
                            ? TextStyle(color: Theme.of(context).disabledColor)
                            : null,
                      ),
                    ),
                  );
                },
              )
              .toList(),
          onChanged: (id) {
            if (id != null) onChanged(id);
          },
        ),
      ),
    );
  }
}

class _PairSelector extends StatelessWidget {
  const _PairSelector({
    required this.ids,
    required this.selected,
    required this.name,
    required this.onSelect,
    required this.colourIdentity,
    required this.showBowlerColours,
  });

  final List<int> ids;
  final int? selected;
  final String Function(int) name;
  final VoidCallback onSelect;
  final String Function(int) colourIdentity;
  final bool showBowlerColours;

  @override
  Widget build(BuildContext context) {
    Widget outlinedName(int id) => BowlerNameOutline(
          enabled: showBowlerColours,
          playerIdentity: colourIdentity(id),
          child: Text(name(id)),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (ids.length == 2) ...[
                        const Text('Pair:'),
                        outlinedName(ids[0]),
                        const Text('/'),
                        outlinedName(ids[1]),
                      ] else
                        const Text('No active two-bowler pair'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onSelect,
                  child: const Text('Select Pair'),
                ),
              ],
            ),
            if (selected != null) ...[
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  const Text('Current:'),
                  outlinedName(selected!),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Select pair and current bowler'),
              ),
            if (showBowlerColours && ids.isNotEmpty) ...[
              const SizedBox(height: 8),
              BowlerColourLegend(
                enabled: showBowlerColours,
                bowlerIds: ids,
                name: name,
                playerIdentity: colourIdentity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoringPad extends StatelessWidget {
  const _ScoringPad({
    required this.enabled,
    required this.onRuns,
    required this.onWide,
    required this.onNoBall,
    required this.onBye,
    required this.onLegBye,
  });

  final bool enabled;
  final ValueChanged<int> onRuns;
  final VoidCallback onWide;
  final VoidCallback onNoBall;
  final VoidCallback onBye;
  final VoidCallback onLegBye;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            for (final runs in [0, 1, 2, 3, 4, 6])
              FilledButton(
                onPressed: enabled ? () => onRuns(runs) : null,
                child: Text(
                  '$runs',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            OutlinedButton(
              onPressed: enabled ? onWide : null,
              child: const Text('WD'),
            ),
            OutlinedButton(
              onPressed: enabled ? onNoBall : null,
              child: const Text('NB'),
            ),
            OutlinedButton(
              onPressed: enabled ? onBye : null,
              child: const Text('B'),
            ),
            OutlinedButton(
              onPressed: enabled ? onLegBye : null,
              child: const Text('LB'),
            ),
          ],
        ),
      ),
    );
  }
}
