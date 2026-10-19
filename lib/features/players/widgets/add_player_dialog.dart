import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/media/local_image_service.dart';
import '../../../domain/players/enums/batting_style.dart';
import '../../../domain/players/enums/bowling_style.dart';
import '../../../domain/players/models/player.dart';
import '../providers/player_provider.dart';
import 'player_avatar.dart';

Future<Player?> showAddPlayerDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final nameController = TextEditingController();
  final displayController = TextEditingController();
  final jerseyController = TextEditingController();
  var battingStyle = BattingStyle.right;
  var bowlingStyle = BowlingStyle.right;
  String? photoPath;

  try {
    final imageService = LocalImageService();
    final result = await showDialog<Player>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Player'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerAvatar(
                  displayName: displayController.text,
                  photoPath: photoPath,
                  radius: 48,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final path = await imageService.pickAndPersist(
                      source: ImageSource.gallery,
                    );
                    if (path != null) setState(() => photoPath = path);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(photoPath == null ? 'Add Photo' : 'Change Photo'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: displayController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jerseyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jersey number (optional)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BattingStyle>(
                  initialValue: battingStyle,
                  decoration: const InputDecoration(labelText: 'Batting style'),
                  items: BattingStyle.values
                      .map((style) => DropdownMenuItem(value: style, child: Text(style.label)))
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
                      .map((style) => DropdownMenuItem(value: style, child: Text(style.label)))
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final displayName = displayController.text.trim();
                if (name.isEmpty || displayName.isEmpty) return;

                final jerseyText = jerseyController.text.trim();
                final jerseyNumber = jerseyText.isEmpty ? null : int.tryParse(jerseyText);
                if (jerseyText.isNotEmpty && jerseyNumber == null) return;

                final player = await ref.read(playerProvider.notifier).add(
                  name: name,
                  displayName: displayName,
                  photoPath: photoPath,
                  jerseyNumber: jerseyNumber,
                  battingStyle: battingStyle,
                  bowlingStyle: bowlingStyle,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, player);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    return result;
  } finally {
    nameController.dispose();
    displayController.dispose();
    jerseyController.dispose();
  }
}
