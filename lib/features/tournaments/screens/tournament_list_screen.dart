import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/tournament_provider.dart';
import '../widgets/edit_tournament_dialog.dart';
import '../widgets/tournament_card.dart';

class TournamentListScreen extends ConsumerWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournaments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tournaments/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
      ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load tournaments: $error')),
        data: (tournaments) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: tournaments.isEmpty
                ? const _EmptyTournaments()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                    itemCount: tournaments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tournament = tournaments[index];
                      return TournamentCard(
                        tournament: tournament,
                        onTap: () => context.push('/tournaments/${tournament.id}'),
                        onManage: () => showEditTournamentDialog(context, ref, tournament),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTournaments extends StatelessWidget {
  const _EmptyTournaments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 56),
            const SizedBox(height: 16),
            Text('No tournaments yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Create your first tournament to get started.'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/tournaments/new'),
              icon: const Icon(Icons.add),
              label: const Text('Create Tournament'),
            ),
          ],
        ),
      ),
    );
  }
}
