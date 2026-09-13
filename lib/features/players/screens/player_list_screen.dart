import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';

class PlayerListScreen extends ConsumerWidget {
  const PlayerListScreen({super.key});

  Future<void> _addPlayer(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final displayController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: displayController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  displayController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await ref.read(playerProvider.notifier).add(
            name: nameController.text,
            displayName: displayController.text,
          );
    }
    nameController.dispose();
    displayController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Players')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPlayer(context, ref),
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(player.displayName.isEmpty ? '?' : player.displayName[0].toUpperCase())),
                  title: Text(player.displayName),
                  subtitle: Text(player.name),
                  trailing: IconButton(
                    tooltip: 'Deactivate player',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () => ref.read(playerProvider.notifier).deactivate(player.id),
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
