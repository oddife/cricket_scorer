import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/tournament_provider.dart';
import '../widgets/tournament_form.dart';

class TournamentSetupScreen extends ConsumerWidget {
  const TournamentSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Tournament')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: TournamentForm(
              onSave: ({required name, required type}) async {
                await ref.read(tournamentProvider.notifier).add(
                      name: name,
                      type: type,
                    );
                if (context.mounted) context.pop();
              },
            ),
          ),
        ),
      ),
    );
  }
}
