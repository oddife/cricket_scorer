import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/media/local_image_service.dart';
import '../../../domain/teams/models/team.dart';
import '../providers/team_provider.dart';
import 'team_logo.dart';

Future<Team?> showAddTeamDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final shortController = TextEditingController();
  String? logoPath;

  try {
    final imageService = LocalImageService();
    return await showDialog<Team>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TeamLogo(teamName: nameController.text, logoPath: logoPath, radius: 48),
                TextButton.icon(
                  onPressed: () async {
                    final path = await imageService.pickAndPersist(source: ImageSource.gallery);
                    if (path != null) setState(() => logoPath = path);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(logoPath == null ? 'Add Team Logo' : 'Change Logo'),
                ),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final team = await ref.read(teamProvider.notifier).add(
                  name: nameController.text,
                  shortName: shortController.text,
                  logoPath: logoPath,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, team);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  } finally {
    nameController.dispose();
    shortController.dispose();
  }
}
