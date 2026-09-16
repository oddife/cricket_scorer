import 'package:flutter/material.dart';

import '../../../domain/players/models/player.dart';

class TeamSquadList extends StatelessWidget {
  const TeamSquadList({
    required this.players,
    required this.onRemove,
    super.key,
  });

  final List<Player> players;
  final Future<void> Function(Player player) onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: players.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = players[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                player.displayName.isEmpty
                    ? '?'
                    : player.displayName[0].toUpperCase(),
              ),
            ),
            title: Text(player.displayName),
            subtitle: Text(
              '${player.name}${player.jerseyNumber == null ? '' : ' • #${player.jerseyNumber}'}',
            ),
            trailing: IconButton(
              tooltip: 'Remove from team',
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: () => onRemove(player),
            ),
          ),
        );
      },
    );
  }
}
