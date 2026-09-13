import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/team_provider.dart';

class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key});

  Future<void> _addTeam(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final shortController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Team name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shortController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Short name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || shortController.text.trim().isEmpty) {
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
      await ref.read(teamProvider.notifier).add(
            name: nameController.text,
            shortName: shortController.text,
          );
    }
    nameController.dispose();
    shortController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTeam(context, ref),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Add Team'),
      ),
      body: teams.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load teams: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No teams yet. Add your first team.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final team = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(team.shortName.isEmpty ? '?' : team.shortName[0])),
                  title: Text(team.name),
                  subtitle: Text(team.shortName),
                  trailing: IconButton(
                    tooltip: 'Deactivate team',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () => ref.read(teamProvider.notifier).deactivate(team.id),
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
