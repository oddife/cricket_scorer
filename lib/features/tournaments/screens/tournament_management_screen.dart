import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/teams/models/team.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/tournament_provider.dart';
import '../widgets/tournament_team_picker.dart';

class TournamentManagementScreen extends ConsumerWidget {
  const TournamentManagementScreen({required this.tournamentId, super.key});

  final int tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref
        .watch(tournamentProvider)
        .where((item) => item.id == tournamentId)
        .firstOrNull;

    if (tournament == null) {
      return const Scaffold(body: Center(child: Text('Tournament not found')));
    }

    final selectedIds = ref.read(tournamentProvider.notifier).teamIds(tournamentId);
    final teamsAsync = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Management')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(tournament.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Manage the teams participating in this tournament.'),
              const SizedBox(height: 24),
              const Text('Tournament Teams', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TournamentTeamPicker(
                selectedTeamIds: selectedIds,
                onChanged: (teamId) {
                  final notifier = ref.read(tournamentProvider.notifier);
                  if (selectedIds.contains(teamId)) {
                    notifier.removeTeam(tournamentId, teamId);
                  } else {
                    notifier.addTeam(tournamentId, teamId);
                  }
                },
              ),
              const SizedBox(height: 28),
              teamsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (teams) => _SelectedTeams(
                  teams: teams,
                  selectedIds: selectedIds,
                  onRemove: (teamId) =>
                      ref.read(tournamentProvider.notifier).removeTeam(tournamentId, teamId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedTeams extends StatelessWidget {
  const _SelectedTeams({
    required this.teams,
    required this.selectedIds,
    required this.onRemove,
  });

  final List<Team> teams;
  final Set<int> selectedIds;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = teams.where((team) => selectedIds.contains(team.id)).toList();
    if (selected.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.groups_outlined),
          title: Text('No teams selected'),
          subtitle: Text('Select one or more active teams above.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < selected.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(selected[i].name),
              subtitle: Text(selected[i].shortName),
              trailing: IconButton(
                tooltip: 'Remove team',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => onRemove(selected[i].id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
