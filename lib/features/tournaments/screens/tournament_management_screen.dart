import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/tournament_provider.dart';
import '../providers/tournament_team_provider.dart';
import '../widgets/tournament_participating_teams.dart';
import '../widgets/tournament_points_editor.dart';
import '../widgets/tournament_team_picker.dart';

class TournamentManagementScreen extends ConsumerWidget {
  const TournamentManagementScreen({required this.tournamentId, super.key});

  final int tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentProvider);
    final selectedAsync = ref.watch(tournamentTeamsProvider(tournamentId));
    final controller = ref.read(tournamentTeamControllerProvider(tournamentId));

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
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tournament.name, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            const Text('Manage participating teams and tournament points.'),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/tournaments/$tournamentId'),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Tournament Profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Participating Teams', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  selectedAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Unable to load tournament teams: $error'),
                    data: (selected) => TournamentTeamPicker(
                      selectedTeamIds: selected.map((team) => team.id).toSet(),
                      onChanged: (teamId) async {
                        final selectedIds = selected.map((team) => team.id).toSet();
                        if (selectedIds.contains(teamId)) {
                          await controller.removeTeam(teamId);
                        } else {
                          await controller.addTeam(teamId);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  selectedAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (selected) => TournamentParticipatingTeams(
                      teams: selected,
                      onRemove: controller.removeTeam,
                      onManageSquad: (teamId) => context.push('/teams/$teamId'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('Points Rules', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _PointsRulesSection(tournamentId: tournamentId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PointsRulesSection extends ConsumerWidget {
  const _PointsRulesSection({required this.tournamentId});

  final int tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(tournamentPointsRulesProvider(tournamentId));
    return rulesAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())),
      error: (error, _) => Card(child: ListTile(title: const Text('Unable to load points rules'), subtitle: Text('$error'))),
      data: (rules) => TournamentPointsEditor(rules: rules),
    );
  }
}
