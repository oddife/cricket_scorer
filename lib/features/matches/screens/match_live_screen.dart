import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/players/models/player.dart';
import '../../../domain/scoring/enums/run_out_end.dart';
import '../../../domain/scoring/enums/wicket_type.dart';
import '../../../domain/scoring/models/wicket_input.dart';
import '../../../domain/scoring/services/wicket_workflow_service.dart';
import '../../players/providers/player_provider.dart';
import '../providers/innings_provider.dart';
import '../providers/live_scoring_provider.dart';
import '../providers/match_provider.dart';

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
      appBar: AppBar(title: const Text('Live Scoring')),
      body: match.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load match: $e')),
        data: (m) {
          if (m == null) return const Center(child: Text('Match not found.'));
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
                  error: (e, _) => Center(child: Text('Unable to load player names: $e')),
                  data: (globalPlayers) => _ScoringView(
                    matchName: m.name,
                    inningsId: sorted.first.id,
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
    required this.inningsId,
    required this.matchPlayers,
    required this.globalPlayers,
  });

  final String matchName;
  final int inningsId;
  final List matchPlayers;
  final List<Player> globalPlayers;

  String name(int id) => globalPlayers
      .where((p) => p.id == id)
      .firstOrNull
      ?.displayName ?? 'Player $id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveScoringProvider(inningsId));
    return live.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Unable to load scoring state: $e')),
      data: (data) {
        final s = data.score;
        final striker = s.batters[s.strikerId];
        final nonStriker = s.batters[s.nonStrikerId];
        final bowler = s.bowlers[s.bowlerId];
        final bowlers = matchPlayers
            .where((p) =>
                p.teamId == data.innings.bowlingTeamId && p.isPlaying)
            .map((p) => p.playerId as int)
            .toList();
        final enabled = data.selectedBowlerId != null &&
            (!data.innings.twoBowlerMode || data.activeTwoBowlerIds.length == 2);

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final batterCard = Card(
              child: Column(
                children: [
                  const ListTile(title: Text('Batters'), trailing: Text('R  B')),
                  ListTile(
                    leading: const Text('▶'),
                    title: Text(name(s.strikerId)),
                    trailing: Text('${striker?.runs ?? 0}  ${striker?.balls ?? 0}'),
                  ),
                  ListTile(
                    title: Text(name(s.nonStrikerId)),
                    trailing: Text('${nonStriker?.runs ?? 0}  ${nonStriker?.balls ?? 0}'),
                  ),
                ],
              ),
            );
            final bowlerCard = Card(
              child: ListTile(
                leading: const Icon(Icons.sports_baseball),
                title: Text(s.bowlerId == 0 ? 'Select bowler' : name(s.bowlerId)),
                subtitle: Text(
                  'Overs ${bowler == null ? '0.0' : '${bowler.legalBalls ~/ s.ballsPerOver}.${bowler.legalBalls % s.ballsPerOver}'}'
                  '  •  Runs ${bowler?.runsConceded ?? 0}'
                  '  •  Wickets ${bowler?.wickets ?? 0}',
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
                                    Text(matchName,
                                        style: Theme.of(context).textTheme.titleLarge),
                                    Text('Innings ${data.innings.inningsNumber}'),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${s.score}/${s.wickets}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${s.completedOvers}.${s.legalBallsInCurrentOver} ov  •  CRR '
                                    '${s.legalBalls == 0 ? '0.00' : (s.score / (s.legalBalls / s.ballsPerOver)).toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
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
                      const SizedBox(height: 12),
                      data.innings.twoBowlerMode
                          ? _PairSelector(
                              ids: data.activeTwoBowlerIds,
                              selected: data.selectedBowlerId,
                              bowlers: bowlers,
                              name: name,
                              onSelect: () => _pairDialog(context, ref, data, bowlers),
                            )
                          : _BowlerSelector(
                              selected: data.selectedBowlerId,
                              bowlers: bowlers,
                              name: name,
                              onChanged: (id) => ref
                                  .read(liveScoringProvider(inningsId).notifier)
                                  .selectBowler(id),
                            ),
                      const SizedBox(height: 12),
                      _ScoringPad(
                        enabled: enabled,
                        onRuns: (r) => _action(context, ref, () => ref
                            .read(liveScoringProvider(inningsId).notifier)
                            .scoreRuns(r)),
                        onWide: () => _action(context, ref, () => ref
                            .read(liveScoringProvider(inningsId).notifier)
                            .scoreWide(1)),
                        onNoBall: () => _action(context, ref, () => ref
                            .read(liveScoringProvider(inningsId).notifier)
                            .scoreNoBall()),
                        onBye: () => _action(context, ref, () => ref
                            .read(liveScoringProvider(inningsId).notifier)
                            .scoreBye(1)),
                        onLegBye: () => _action(context, ref, () => ref
                            .read(liveScoringProvider(inningsId).notifier)
                            .scoreLegBye(1)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: data.canUndo
                            ? () => ref.read(liveScoringProvider(inningsId).notifier).undo()
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: enabled
                            ? () => _wicketDialog(context, ref, data, matchPlayers)
                            : null,
                        icon: const Icon(Icons.sports_cricket),
                        label: const Text('Wicket'),
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
      BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    await action();
    if (!context.mounted) return;
    ref.read(liveScoringProvider(inningsId)).whenOrNull(
          error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
          ),
        );
  }

  Future<void> _wicketDialog(
    BuildContext context,
    WidgetRef ref,
    LiveScoringState data,
    List matchPlayers,
  ) async {
    final battingPlayers = matchPlayers
        .where((p) => p.teamId == data.innings.battingTeamId && p.isPlaying)
        .map((p) => p.playerId as int)
        .toList();
    final fielders = matchPlayers
        .where((p) => p.teamId == data.innings.bowlingTeamId && p.isPlaying)
        .map((p) => p.playerId as int)
        .toList();
    final alreadyBatted = data.score.batters.keys.toSet();
    final replacements = battingPlayers
        .where((id) => !alreadyBatted.contains(id))
        .toList();

    WicketType type = WicketType.bowled;
    int dismissed = data.score.strikerId;
    int? fielder;
    RunOutEnd? runOutEnd;
    int completedRuns = 0;
    bool crossed = false;
    int? replacement;

    final result = await showDialog<WicketInput>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final needsFielder = type == WicketType.caught ||
              type == WicketType.runOut ||
              type == WicketType.stumped;
          final strikerOnly = type != WicketType.runOut &&
              type != WicketType.obstructingField;
          if (strikerOnly) dismissed = data.score.strikerId;
          if (!needsFielder) fielder = null;
          if (type != WicketType.runOut) {
            runOutEnd = null;
            completedRuns = 0;
            crossed = false;
          }
          return AlertDialog(
            title: const Text('Record Wicket'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<WicketType>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Dismissal',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        WicketType.bowled,
                        WicketType.caught,
                        WicketType.lbw,
                        WicketType.runOut,
                        WicketType.stumped,
                        WicketType.hitWicket,
                        WicketType.obstructingField,
                        WicketType.overFence,
                      ].map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(_wicketLabel(value)),
                          )).toList(),
                      onChanged: (value) => setState(() {
                        if (value != null) type = value;
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (!strikerOnly)
                      DropdownButtonFormField<int>(
                        initialValue: dismissed,
                        decoration: const InputDecoration(
                          labelText: 'Dismissed batter',
                          border: OutlineInputBorder(),
                        ),
                        items: [data.score.strikerId, data.score.nonStrikerId]
                            .map((id) => DropdownMenuItem(value: id, child: Text(name(id))))
                            .toList(),
                        onChanged: (value) => setState(() {
                          if (value != null) dismissed = value;
                        }),
                      ),
                    if (needsFielder) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: fielder,
                        decoration: const InputDecoration(
                          labelText: 'Fielder / wicketkeeper',
                          border: OutlineInputBorder(),
                        ),
                        items: fielders
                            .map((id) => DropdownMenuItem(value: id, child: Text(name(id))))
                            .toList(),
                        onChanged: (value) => setState(() => fielder = value),
                      ),
                    ],
                    if (type == WicketType.runOut) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<RunOutEnd>(
                        initialValue: runOutEnd,
                        decoration: const InputDecoration(
                          labelText: 'Wicket broken at',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          RunOutEnd.strikerEnd,
                          RunOutEnd.nonStrikerEnd,
                        ].map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(_runOutEndLabel(value)),
                            )).toList(),
                        onChanged: (value) => setState(() => runOutEnd = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: completedRuns,
                        decoration: const InputDecoration(
                          labelText: 'Completed runs',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                        onChanged: (value) => setState(() => completedRuns = value ?? 0),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Crossed before wicket was broken'),
                        value: crossed,
                        onChanged: (value) => setState(() => crossed = value),
                      ),
                    ],
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      initialValue: replacement,
                      decoration: const InputDecoration(
                        labelText: 'Replacement batter',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Select later')),
                        ...replacements.map((id) => DropdownMenuItem<int?>(
                              value: id,
                              child: Text(name(id)),
                            )),
                      ],
                      onChanged: (value) => setState(() => replacement = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    WicketInput(
                      type: type,
                      dismissedPlayerId: dismissed,
                      fielderId: fielder,
                      runOutEnd: runOutEnd,
                      completedRuns: completedRuns,
                      crossedBeforeWicket: crossed,
                      replacementBatterId: replacement,
                    ),
                  );
                },
                child: const Text('Confirm Wicket'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      final wicket = const WicketWorkflowService().create(
        input: result,
        strikerId: data.score.strikerId,
        nonStrikerId: data.score.nonStrikerId,
        deliveryType: DeliveryType.normal,
        eligibleFielderIds: fielders.toSet(),
      );
      await ref.read(liveScoringProvider(inningsId).notifier).scoreWicket(wicket);
      if (!context.mounted) return;
      ref.read(liveScoringProvider(inningsId)).whenOrNull(
            error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
            ),
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _pairDialog(
      BuildContext context, WidgetRef ref, LiveScoringState data, List<int> bowlers) async {
    final selected = <int>{...data.activeTwoBowlerIds};
    final result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select two bowlers'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final id in bowlers)
                  CheckboxListTile(
                    value: selected.contains(id),
                    title: Text(name(id)),
                    onChanged: (value) => setState(() {
                      if (value == true && selected.length < 2) {
                        selected.add(id);
                      } else if (value != true) {
                        selected.remove(id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.length == 2
                  ? () => Navigator.pop(dialogContext, selected.toList())
                  : null,
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      ref
          .read(liveScoringProvider(data.innings.id).notifier)
          .selectTwoBowlerPair(result);
    }
  }

  static String _wicketLabel(WicketType type) => switch (type) {
        WicketType.bowled => 'Bowled',
        WicketType.caught => 'Caught',
        WicketType.lbw => 'LBW',
        WicketType.runOut => 'Run Out',
        WicketType.stumped => 'Stumped',
        WicketType.hitWicket => 'Hit Wicket',
        WicketType.retired => 'Retired',
        WicketType.obstructingField => 'Obstructing the Field',
        WicketType.overFence => 'Over Fence',
      };

  static String _runOutEndLabel(RunOutEnd end) => switch (end) {
        RunOutEnd.strikerEnd => "Striker's End",
        RunOutEnd.nonStrikerEnd => "Non-Striker's End",
      };
}

class _BowlerSelector extends StatelessWidget {
  const _BowlerSelector({
    required this.selected,
    required this.bowlers,
    required this.name,
    required this.onChanged,
  });
  final int? selected;
  final List<int> bowlers;
  final String Function(int) name;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<int>(
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: 'Current bowler',
              border: OutlineInputBorder(),
            ),
            items: bowlers
                .map((id) => DropdownMenuItem(value: id, child: Text(name(id))))
                .toList(),
            onChanged: (id) {
              if (id != null) onChanged(id);
            },
          ),
        ),
      );
}

class _PairSelector extends StatelessWidget {
  const _PairSelector({
    required this.ids,
    required this.selected,
    required this.bowlers,
    required this.name,
    required this.onSelect,
  });
  final List<int> ids;
  final int? selected;
  final List<int> bowlers;
  final String Function(int) name;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(ids.length == 2
              ? 'Pair: ${name(ids[0])} / ${name(ids[1])}'
              : 'No active two-bowler pair'),
          subtitle: Text(selected == null
              ? 'Select pair and current bowler'
              : 'Current: ${name(selected!)}'),
          trailing: OutlinedButton(
            onPressed: onSelect,
            child: const Text('Select Pair'),
          ),
        ),
      );
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
  Widget build(BuildContext context) => Card(
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
              for (final r in [0, 1, 2, 3, 4, 6])
                FilledButton(
                  onPressed: enabled ? () => onRuns(r) : null,
                  child: Text(
                    '$r',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              OutlinedButton(onPressed: enabled ? onWide : null, child: const Text('WD')),
              OutlinedButton(onPressed: enabled ? onNoBall : null, child: const Text('NB')),
              OutlinedButton(onPressed: enabled ? onBye : null, child: const Text('B')),
              OutlinedButton(onPressed: enabled ? onLegBye : null, child: const Text('LB')),
            ],
          ),
        ),
      );
}
