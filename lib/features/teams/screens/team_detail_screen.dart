import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/players/models/player.dart';
import '../../players/providers/player_provider.dart';
import '../providers/team_player_provider.dart';
import '../providers/team_provider.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({required this.teamId, super.key});

  final int teamId;

  Future<void> _addPlayer(
    BuildContext context,
    WidgetRef ref,
    List<Player> members,
  ) async {
    final players = ref.read(playerProvider).value ?? const <Player>[];
    final memberIds = members.map((player) => player.id).toSet();
    final available =
        players.where((player) => !memberIds.contains(player.id)).toList();

    if (available.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available players. Add players first.')),
        );
      }
      return;
    }

    final selected = await showDialog<Player>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Add Player to Team'),
        children: available
            .map(
              (player) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, player),
                child: Text(player.displayName),
              ),
            )
            .toList(growable: false),
      ),
    );

    if (selected == null || !context.mounted) return;

    try {
      await ref.read(teamPlayerRepositoryProvider).addPlayerToTeam(
            teamId: teamId,
            playerId: selected.id,
          );
      ref.invalidate(teamPlayersProvider(teamId));
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref
        .watch(teamProvider)
        .value
        ?.where((item) => item.id == teamId)
        .firstOrNull;
    final members = ref.watch(teamPlayersProvider(teamId));

    if (team == null) {
      return const Scaffold(body: Center(child: Text('Team not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        actions: [
          IconButton(
            tooltip: 'Add player',
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () =>
                _addPlayer(context, ref, members.value ?? const []),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPlayer(context, ref, members.value ?? const []),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Player'),
      ),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load squad: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No players in this team yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = items[index];
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
                  subtitle: Text(player.name),
                  trailing: IconButton(
                    tooltip: 'Remove from team',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () async {
                      await ref
                          .read(teamPlayerRepositoryProvider)
                          .removePlayerFromTeam(teamId, player.id);
                      ref.invalidate(teamPlayersProvider(teamId));
                    },
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
