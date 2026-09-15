import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/teams/models/team.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/tournament_team_provider.dart';
import '../providers/tournament_provider.dart';
import '../widgets/tournament_team_picker.dart';

class TournamentManagementScreen extends ConsumerWidget {
  const TournamentManagementScreen({required this.tournamentId, super.key});

  final int tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentProvider);
    final selectedAsync = ref.watch(tournamentTeamNotifierProvider(tournamentId));
    final teamsAsync = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Management')),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load tournament: $error')),
        data: (tournaments) {
          final tournament = tournaments.where((item) => item.id == tournamentId).firstOrNull;
          if (tournament == null) return const Center(child: Text('Tournament not found'));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(tournament.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Manage the teams participating in this tournament.'),
                  const SizedBox(height: 24),
                  const Text('Add Teams', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  selectedAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Unable to load tournament teams: $error'),
                    data: (selected) => TournamentTeamPicker(
                      selectedTeamIds: selected.map((team) => team.id).toSet(),
                      onChanged: (teamId) async {
                        final selectedIds = selected.map((team) => team.id).toSet();
                        final notifier = ref.read(
                          tournamentTeamNotifierProvider(tournamentId).notifier,
                        );
                        if (selectedIds.contains(teamId)) {
                          await notifier.removeTeam(teamId);
                        } else {
                          await notifier.addTeam(teamId);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  teamsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (teams) => selectedAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (selected) => _SelectedTeams(
                        teams: teams,
                        selectedIds: selected.map((team) => team.id).toSet(),
                        onRemove: (teamId) => ref
                            .read(tournamentTeamNotifierProvider(tournamentId).notifier)
                            .removeTeam(teamId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedTeams extends StatelessWidget {
  const _SelectedTeams({required this.teams, required this.selectedIds, required this.onRemove});

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
