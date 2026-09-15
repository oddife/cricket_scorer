import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/players/models/player.dart';
import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/models/delivery_input.dart';
import '../../../domain/scoring/services/wicket_workflow_service.dart';
import '../../players/providers/player_provider.dart';
import '../providers/innings_provider.dart';
import '../providers/live_scoring_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/delivery_aware_wicket_dialog.dart';

class MatchLiveScreen extends ConsumerWidget {
  const MatchLiveScreen({super.key, required this.matchId});

  final int matchId;

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
                return const Center(child: Text('No innings has been started.'));
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
                    inningsId: sorted.last.id,
                    matchPlayers: matchPlayers,
                    globalPlayers: globalPlayers,
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

class _ScoringView extends ConsumerWidget {
  const _ScoringView({
    required this.matchName,
    required this.matchId,
    required this.matchInningsCount,
    required this.inningsId,
    required this.matchPlayers,
    required this.globalPlayers,
  });

  final String matchName;
  final int matchId;
  final int matchInningsCount;
  final int inningsId;
  final List matchPlayers;
  final List<Player> globalPlayers;

  String name(int id) =>
      globalPlayers.where((p) => p.id == id).firstOrNull?.displayName ??
      'Player $id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveScoringProvider(inningsId));

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
        final strikerId = data.liveStrikerId;
        final nonStrikerId = data.liveNonStrikerId;
        final striker = s.batters[strikerId];
        final nonStriker = s.batters[nonStrikerId];
        final bowler = s.bowlers[s.bowlerId];

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
                              ),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Manage'),
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
              child: ListTile(
                leading: const Icon(Icons.sports_baseball),
                title: Text(
                  s.bowlerId == 0 ? 'Select bowler' : name(s.bowlerId),
                ),
                subtitle: Text(
                  'Overs ${bowler == null ? '0.0' : '${bowler.legalBalls ~/ s.ballsPerOver}.${bowler.legalBalls % s.ballsPerOver}'} '
                  '• Runs ${bowler?.runsConceded ?? 0} '
                  '• Wickets ${bowler?.wickets ?? 0}',
                ),
              ),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              ],
                            ),
                          ),
                        ),
                      if (s.inningsComplete)
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
                            onChanged: (id) => ref
                                .read(liveScoringProvider(inningsId).notifier)
                                .selectBowler(id),
                          )
                        else if (finalOddOver)
                          _BowlerSelector(
                            selected: data.selectedBowlerId,
                            bowlers: bowlers,
                            name: name,
                            label: 'Final over bowler',
                            onChanged: (id) => ref
                                .read(liveScoringProvider(inningsId).notifier)
                                .selectFinalOverBowler(id),
                          )
                        else
                          _PairSelector(
                            ids: data.activeTwoBowlerIds,
                            selected: data.selectedBowlerId,
                            name: name,
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
            );
          },
        );
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
      final wicket = const WicketWorkflowService().create(
        input: result,
        strikerId: data.liveStrikerId,
        nonStrikerId: data.liveNonStrikerId,
        deliveryType: result.deliveryType,
        eligibleFielderIds: fielders.toSet(),
      );
      await ref
          .read(liveScoringProvider(inningsId).notifier)
          .scoreWicketDelivery(
            DeliveryInput(
              deliveryType: result.deliveryType,
              batterRuns: result.batterRuns,
              byeRuns: result.byeRuns,
              legByeRuns: result.legByeRuns,
              wideRuns: result.wideRuns,
              noBallRuns: result.noBallRuns,
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

  Future<void> _manageBatters(
    BuildContext context,
    WidgetRef ref,
    LiveScoringState data,
    List<int> players,
  ) async {
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
                          id != nonStriker && data.score.batters[id]?.isOut != true,
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
                          id != striker && data.score.batters[id]?.isOut != true,
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
    final selected = <int>{...data.activeTwoBowlerIds};
    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Select two bowlers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: bowlers
                .map(
                  (id) => CheckboxListTile(
                    value: selected.contains(id),
                    title: Text(name(id)),
                    onChanged: (value) {
                      setState(() {
                        if (value == true && selected.length < 2) {
                          selected.add(id);
                        } else if (value != true) {
                          selected.remove(id);
                        }
                      });
                    },
                  ),
                )
                .toList(),
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
        () => ref
            .read(liveScoringProvider(inningsId).notifier)
            .selectTwoBowlerPair(result),
      );
    }
  }
}

class _BowlerSelector extends StatelessWidget {
  const _BowlerSelector({
    required this.selected,
    required this.bowlers,
    required this.name,
    required this.onChanged,
    this.label = 'Current bowler',
  });

  final int? selected;
  final List<int> bowlers;
  final String Function(int) name;
  final ValueChanged<int> onChanged;
  final String label;

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
                (id) => DropdownMenuItem(
                  value: id,
                  child: Text(name(id)),
                ),
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
  });

  final List<int> ids;
  final int? selected;
  final String Function(int) name;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          ids.length == 2
              ? 'Pair: ${name(ids[0])} / ${name(ids[1])}'
              : 'No active two-bowler pair',
        ),
        subtitle: Text(
          selected == null
              ? 'Select pair and current bowler'
              : 'Current: ${name(selected!)}',
        ),
        trailing: OutlinedButton(
          onPressed: onSelect,
          child: const Text('Select Pair'),
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
