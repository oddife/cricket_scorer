import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/players/models/player.dart';
import '../../../players/providers/player_provider.dart';
import '../../../players/widgets/add_player_dialog.dart';
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
    required this.players,
    required this.playersPerTeam,
  });

  final String teamAName;
  final String teamBName;
  final int teamAId;
  final int teamBId;
  final List<Player> players;
  final int playersPerTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playingXiProvider);
    final notifier = ref.read(playingXiProvider.notifier);

    return Column(
      children: [
        _TeamEditor(
          teamId: teamAId,
          teamName: teamAName,
          players: players,
          selected: state.teamAPlayerIds,
          excludedPlayerIds: state.teamBPlayerIds.toSet(),
          order: state.teamABattingOrder,
          requiredCount: playersPerTeam,
          onSelected: notifier.setTeamAPlayers,
          onOrderChanged: notifier.setTeamABattingOrder,
        ),
        const SizedBox(height: 16),
        _TeamEditor(
          teamId: teamBId,
          teamName: teamBName,
          players: players,
          selected: state.teamBPlayerIds,
          excludedPlayerIds: state.teamAPlayerIds.toSet(),
          order: state.teamBBattingOrder,
          requiredCount: playersPerTeam,
          onSelected: notifier.setTeamBPlayers,
          onOrderChanged: notifier.setTeamBBattingOrder,
        ),
      ],
    );
  }
}

class _TeamEditor extends ConsumerWidget {
  const _TeamEditor({
    required this.teamId,
    required this.teamName,
    required this.players,
    required this.selected,
    required this.excludedPlayerIds,
    required this.order,
    required this.requiredCount,
    required this.onSelected,
    required this.onOrderChanged,
  });

  final int teamId;
  final String teamName;
  final List<Player> players;
  final List<int> selected;
  final Set<int> excludedPlayerIds;
  final List<int> order;
  final int requiredCount;
  final ValueChanged<List<int>> onSelected;
  final ValueChanged<List<int>> onOrderChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availablePlayers = players
        .where((player) => !excludedPlayerIds.contains(player.id))
        .toList();
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
                  child: Text(
                    teamName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${selected.length}/$requiredCount'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<List<int>>(
                      context: context,
                      builder: (_) => PlayerSelectionDialog(
                        title: '$teamName Players',
                        players: availablePlayers,
                        initialSelection: selected,
                        requiredCount: requiredCount,
                      ),
                    );
                    if (result != null) onSelected(result);
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Select Players'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final player = await showAddPlayerDialog(context, ref);
                    if (player == null || !context.mounted) return;

                    ref.invalidate(playerProvider);

                    if (selected.length < requiredCount &&
                        !excludedPlayerIds.contains(player.id)) {
                      onSelected([...selected, player.id]);
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create New Player'),
                ),
              ],
            ),
            if (selectedPlayers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Batting order',
                style: Theme.of(context).textTheme.titleSmall,
              ),
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
