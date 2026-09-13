import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/players/enums/batting_style.dart';
import '../../../domain/players/enums/bowling_style.dart';
import '../providers/player_provider.dart';

class PlayerListScreen extends ConsumerWidget {
  const PlayerListScreen({super.key});

  Future<void> _addPlayer(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final displayController = TextEditingController();
    final jerseyController = TextEditingController();
    var battingStyle = BattingStyle.right;
    var bowlingStyle = BowlingStyle.right;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Player'),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 12),
                TextField(
                  controller: jerseyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jersey number (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BattingStyle>(
                  initialValue: battingStyle,
                  decoration: const InputDecoration(labelText: 'Batting style'),
                  items: BattingStyle.values
                      .map(
                        (style) => DropdownMenuItem(
                          value: style,
                          child: Text(style.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => battingStyle = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BowlingStyle>(
                  initialValue: bowlingStyle,
                  decoration: const InputDecoration(labelText: 'Bowling style'),
                  items: BowlingStyle.values
                      .map(
                        (style) => DropdownMenuItem(
                          value: style,
                          child: Text(style.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => bowlingStyle = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
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
      ),
    );

    final jerseyText = jerseyController.text.trim();
    final jerseyNumber = jerseyText.isEmpty ? null : int.tryParse(jerseyText);

    if (result == true && context.mounted) {
      await ref.read(playerProvider.notifier).add(
            name: nameController.text,
            displayName: displayController.text,
            jerseyNumber: jerseyNumber,
            battingStyle: battingStyle,
            bowlingStyle: bowlingStyle,
          );
    }
    nameController.dispose();
    displayController.dispose();
    jerseyController.dispose();
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
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = items[index];
              final jersey = player.jerseyNumber == null
                  ? ''
                  : ' • #${player.jerseyNumber}';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      player.displayName.isEmpty ? '?' : player.displayName[0].toUpperCase(),
                    ),
                  ),
                  title: Text(player.displayName),
                  subtitle: Text(
                    '${player.name}$jersey\n${player.battingStyle.label} • ${player.bowlingStyle.label}',
                  ),
                  isThreeLine: true,
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
