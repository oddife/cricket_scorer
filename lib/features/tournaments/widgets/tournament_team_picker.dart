import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../teams/providers/team_provider.dart';

class TournamentTeamPicker extends ConsumerWidget {
  const TournamentTeamPicker({
    required this.selectedTeamIds,
    required this.onChanged,
    super.key,
  });

  final Set<int> selectedTeamIds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamProvider);

    return teamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Unable to load teams: $error'),
      data: (teams) {
        final available = teams.where((team) => team.isActive).toList();
        if (available.isEmpty) {
          return const Text('No active teams available. Create a team first.');
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final team in available)
              FilterChip(
                label: Text(team.name),
                selected: selectedTeamIds.contains(team.id),
                onSelected: (_) => onChanged(team.id),
              ),
          ],
        );
      },
    );
  }
}
