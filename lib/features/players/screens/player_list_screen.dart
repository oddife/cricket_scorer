import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/player_provider.dart';
import '../widgets/add_player_dialog.dart';
import '../widgets/edit_player_dialog.dart';
import '../widgets/player_avatar.dart';

class PlayerListScreen extends ConsumerWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Players')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddPlayerDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Player'),
      ),
      body: players.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load players: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No players yet. Add your first player.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = items[index];
              final jersey = player.jerseyNumber == null ? '' : ' • #${player.jerseyNumber}';
              return Card(
                child: ListTile(
                  leading: PlayerAvatar(
                    displayName: player.displayName,
                    photoPath: player.photoPath,
                  ),
                  title: Text(player.displayName),
                  subtitle: Text(
                    '${player.name}$jersey\n${player.battingStyle.label} • ${player.bowlingStyle.label}',
                  ),
                  isThreeLine: true,
                  onTap: () => context.push('/players/${player.id}'),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Player management',
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await showEditPlayerDialog(context, ref, player);
                      } else if (value == 'deactivate') {
                        await ref.read(playerProvider.notifier).deactivate(player.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit Player'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deactivate',
                        child: ListTile(
                          leading: Icon(Icons.archive_outlined),
                          title: Text('Deactivate Player'),
                        ),
                      ),
                    ],
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
