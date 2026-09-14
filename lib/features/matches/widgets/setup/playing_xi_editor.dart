import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/players/models/player.dart';
import '../../../players/providers/player_provider.dart';
import '../../../players/widgets/add_player_dialog.dart';
import '../../providers/playing_xi_provider.dart';
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
          teamName: teamAName,
          players: players,
          selected: state.teamAPlayerIds,
          excludedPlayerIds: state.teamBPlayerIds.toSet(),
          requiredCount: playersPerTeam,
          onSelected: notifier.setTeamAPlayers,
        ),
        const SizedBox(height: 16),
        _TeamEditor(
          teamName: teamBName,
          players: players,
          selected: state.teamBPlayerIds,
          excludedPlayerIds: state.teamAPlayerIds.toSet(),
          requiredCount: playersPerTeam,
          onSelected: notifier.setTeamBPlayers,
        ),
      ],
    );
  }
}

class _TeamEditor extends ConsumerWidget {
  const _TeamEditor({
    required this.teamName,
    required this.players,
    required this.selected,
    required this.excludedPlayerIds,
    required this.requiredCount,
    required this.onSelected,
  });

  final String teamName;
  final List<Player> players;
  final List<int> selected;
  final Set<int> excludedPlayerIds;
  final int requiredCount;
  final ValueChanged<List<int>> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availablePlayers = players
        .where((player) => !excludedPlayerIds.contains(player.id))
        .toList();

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
                Text('${selected.length}/$requiredCount available'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Select the players who are available now. You do not need to '
              'fill the team before starting; missing players can be added later.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<List<int>>(
                      context: context,
                      builder: (_) => PlayerSelectionDialog(
                        title: '$teamName Available Players',
                        players: availablePlayers,
                        initialSelection: selected,
                        requiredCount: requiredCount,
                      ),
                    );
                    if (result != null) onSelected(result);
                  },
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Select Players'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final player = await showAddPlayerDialog(context, ref);
                    if (player == null || !context.mounted) return;
                    ref.invalidate(playerProvider);
                    if (!excludedPlayerIds.contains(player.id)) {
                      onSelected([...selected, player.id]);
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create New Player'),
                ),
              ],
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in selected)
                    Chip(
                      label: Text(
                        players
                                .where((p) => p.id == id)
                                .firstOrNull
                                ?.displayName ??
                            'Player $id',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
