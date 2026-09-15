import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/media/local_image_service.dart';
import '../../../domain/tournaments/models/tournament.dart';
import '../providers/tournament_provider.dart';
import 'tournament_logo.dart';
import 'tournament_type_selector.dart';

Future<void> showEditTournamentDialog(
  BuildContext context,
  WidgetRef ref,
  Tournament tournament,
) async {
  final nameController = TextEditingController(text: tournament.name);
  var type = tournament.type;
  var logoPath = tournament.logoPath;
  final imageService = LocalImageService();

  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Tournament'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TournamentLogo(
                  tournamentName: nameController.text,
                  logoPath: logoPath,
                  radius: 48,
                ),
                TextButton.icon(
                  onPressed: () async {
                    final path = await imageService.pickAndPersist(
                      source: ImageSource.gallery,
                    );
                    if (path != null) setState(() => logoPath = path);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    logoPath == null ? 'Add Tournament Logo' : 'Change Logo',
                  ),
                ),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Tournament name'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tournament type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                TournamentTypeSelector(
                  value: type,
                  onChanged: (value) => setState(() => type = value),
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
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                ref.read(tournamentProvider.notifier).update(
                  tournament.copyWith(
                    name: name,
                    type: type,
                    logoPath: logoPath,
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
  }
}
