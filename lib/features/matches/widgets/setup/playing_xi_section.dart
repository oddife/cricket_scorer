import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/players/models/player.dart';
import '../../providers/playing_xi_provider.dart';
import '../../../teams/providers/team_player_provider.dart';
import 'player_selection_dialog.dart';

class PlayingXiSection extends ConsumerWidget {
  const PlayingXiSection({
    super.key,
    required this.teamAId,
    required this.teamBId,
    required this.teamAName,
    required this.teamBName,
    required this.playersPerTeam,
  });

  final int? teamAId;
  final int? teamBId;
  final String teamAName;
  final String teamBName;
  final int playersPerTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xi = ref.watch(playingXiProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.people_outline),
              const SizedBox(width: 10),
              Text('Playing XI', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 8),
            Text('Select $playersPerTeam players for each team and set their batting order.'),
            const SizedBox(height: 20),
            _TeamPicker(
              teamId: teamAId,
              teamName: teamAName,
              selectedIds: xi.teamAPlayerIds,
              playersPerTeam: playersPerTeam,
              onSelected: ref.read(playingXiProvider.notifier).setTeamAPlayers,
            ),
            const SizedBox(height: 12),
            _TeamPicker(
              teamId: teamBId,
              teamName: teamBName,
              selectedIds: xi.teamBPlayerIds,
              playersPerTeam: playersPerTeam,
              onSelected: ref.read(playingXiProvider.notifier).setTeamBPlayers,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamPicker extends ConsumerWidget {
  const _TeamPicker({
    required this.teamId,
    required this.teamName,
    required this.selectedIds,
    required this.playersPerTeam,
    required this.onSelected,
  });

  final int? teamId;
  final String teamName;
  final List<int> selectedIds;
  final int playersPerTeam;
  final ValueChanged<List<int>> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (teamId == null) return _message(context, 'Select this team first.');
    final players = ref.watch(teamPlayersProvider(teamId!));
    return players.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('Unable to load $teamName squad: $error'),
      data: (items) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text('$teamName  •  ${selectedIds.length}/$playersPerTeam')),
            OutlinedButton.icon(
              onPressed: items.isEmpty
                  ? null
                  : () async {
                      final result = await showDialog<List<int>>(
                        context: context,
                        builder: (_) => PlayerSelectionDialog(
                          title: teamName,
                          players: items,
                          initialSelection: selectedIds,
                          requiredCount: playersPerTeam,
                        ),
                      );
                      if (result != null) onSelected(result);
                    },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Select Players'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(BuildContext context, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}

// Keeps the Player type import intentionally explicit for the selection API.
Player _playerReference(Player player) => player;
