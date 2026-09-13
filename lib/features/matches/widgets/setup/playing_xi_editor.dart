import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/players/models/player.dart';
import '../../providers/playing_xi_provider.dart';
import 'batting_order_editor.dart';
import 'player_selection_dialog.dart';

class PlayingXiEditor extends ConsumerWidget {
  const PlayingXiEditor({
    super.key,
    required this.teamAName,
    required this.teamBName,
    required this.teamAId,
    required this.teamBId,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.playersPerTeam,
  });

  final String teamAName;
  final String teamBName;
  final int teamAId;
  final int teamBId;
  final List<Player> teamAPlayers;
  final List<Player> teamBPlayers;
  final int playersPerTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playingXiProvider);
    final notifier = ref.read(playingXiProvider.notifier);

    return Column(
      children: [
        _TeamEditor(
          teamName: teamAName,
          players: teamAPlayers,
          selected: state.teamAPlayerIds,
          order: state.teamABattingOrder,
          requiredCount: playersPerTeam,
          onSelected: notifier.setTeamAPlayers,
          onOrderChanged: notifier.setTeamABattingOrder,
        ),
        const SizedBox(height: 16),
        _TeamEditor(
          teamName: teamBName,
          players: teamBPlayers,
          selected: state.teamBPlayerIds,
          order: state.teamBBattingOrder,
          requiredCount: playersPerTeam,
          onSelected: notifier.setTeamBPlayers,
          onOrderChanged: notifier.setTeamBBattingOrder,
        ),
      ],
    );
  }
}

class _TeamEditor extends StatelessWidget {
  const _TeamEditor({
    required this.teamName,
    required this.players,
    required this.selected,
    required this.order,
    required this.requiredCount,
    required this.onSelected,
    required this.onOrderChanged,
  });

  final String teamName;
  final List<Player> players;
  final List<int> selected;
  final List<int> order;
  final int requiredCount;
  final ValueChanged<List<int>> onSelected;
  final ValueChanged<List<int>> onOrderChanged;

  @override
  Widget build(BuildContext context) {
    final selectedPlayers = [
      for (final id in order)
        ...players.where((player) => player.id == id),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(teamName, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('$${selected.length}/$requiredCount'.replaceFirst(r'$','')),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showDialog<List<int>>(
                  context: context,
                  builder: (_) => PlayerSelectionDialog(
                    title: '$teamName Players',
                    players: players,
                    initialSelection: selected,
                    requiredCount: requiredCount,
                  ),
                );
                if (result != null) onSelected(result);
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Select Players'),
            ),
            if (selectedPlayers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Batting order', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              BattingOrderEditor(
                players: selectedPlayers,
                order: order,
                onChanged: onOrderChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
