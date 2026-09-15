import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/media/local_image_service.dart';
import '../../../domain/players/enums/batting_style.dart';
import '../../../domain/players/enums/bowling_style.dart';
import '../../../domain/players/models/player.dart';
import '../providers/player_provider.dart';
import 'player_avatar.dart';

Future<void> showEditPlayerDialog(
  BuildContext context,
  WidgetRef ref,
  Player player,
) async {
  final nameController = TextEditingController(text: player.name);
  final displayController = TextEditingController(text: player.displayName);
  final jerseyController = TextEditingController(text: player.jerseyNumber?.toString() ?? '');
  var battingStyle = player.battingStyle;
  var bowlingStyle = player.bowlingStyle;
  var photoPath = player.photoPath;

  try {
    final imageService = LocalImageService();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Player'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerAvatar(
                  displayName: displayController.text,
                  photoPath: photoPath,
                  radius: 48,
                ),
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
                TextField(
                  controller: nameController,
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

                await ref.read(playerProvider.notifier).updatePlayer(
                      player.copyWith(
                        name: name,
                        displayName: displayName,
                        photoPath: photoPath,
                        jerseyNumber: jerseyNumber,
                        battingStyle: battingStyle,
                        bowlingStyle: bowlingStyle,
                      ),
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  } finally {
    nameController.dispose();
    displayController.dispose();
    jerseyController.dispose();
  }
}
