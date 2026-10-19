import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/teams/models/team.dart';
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

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: ListView(
                    padding: EdgeInsets.all(isWide ? 28 : 16),
                    children: [
                      _Header(
                        name: tournament.name,
                        type: tournament.type.name,
                        isActive: tournament.isActive,
                        startDate: tournament.startDate,
                        endDate: tournament.endDate,
                        onProfile: () => context.push('/tournaments/$tournamentId'),
                      ),
                      const SizedBox(height: 24),
                      selectedAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Text('Unable to load tournament teams: $error'),
                        data: (selected) => _ManagementContent(
                          tournamentId: tournamentId,
                          tournamentType: tournament.type.name,
                          isActive: tournament.isActive,
                          selected: selected,
                          isWide: isWide,
                          onTeamChanged: (teamId) async {
                            final selectedIds = selected.map((team) => team.id).toSet();
                            if (selectedIds.contains(teamId)) {
                              await controller.removeTeam(teamId);
                            } else {
                              await controller.addTeam(teamId);
                            }
                          },
                          onRemoveTeam: (teamId) => _confirmRemoveTeam(context, controller, teamId),
                          onManageSquad: (teamId) => context.push('/teams/$teamId'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRemoveTeam(
    BuildContext context,
    TournamentTeamController controller,
    int teamId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove team?'),
        content: const Text(
          'This removes the team from this tournament only. The global team and its players are not deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) await controller.removeTeam(teamId);
  }
}

class _ManagementContent extends StatelessWidget {
  const _ManagementContent({
    required this.tournamentId,
    required this.tournamentType,
    required this.isActive,
    required this.selected,
    required this.isWide,
    required this.onTeamChanged,
    required this.onRemoveTeam,
    required this.onManageSquad,
  });

  final int tournamentId;
  final String tournamentType;
  final bool isActive;
  final List<Team> selected;
  final bool isWide;
  final ValueChanged<int> onTeamChanged;
  final ValueChanged<int> onRemoveTeam;
  final ValueChanged<int> onManageSquad;

  @override
  Widget build(BuildContext context) {
    final teamsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.groups_outlined,
          title: 'Participating Teams',
          subtitle: 'Select reusable global teams for this tournament.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TournamentTeamPicker(
              selectedTeamIds: selected.map((team) => team.id).toSet(),
              onChanged: onTeamChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TournamentParticipatingTeams(
          teams: selected,
          onRemove: onRemoveTeam,
          onManageSquad: onManageSquad,
        ),
      ],
    );

    final pointsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.emoji_events_outlined,
          title: 'Points Rules',
          subtitle: 'Configure the points awarded for tournament results.',
        ),
        const SizedBox(height: 12),
        _PointsRulesSection(tournamentId: tournamentId),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCards(teamCount: selected.length, isActive: isActive, tournamentType: tournamentType),
        const SizedBox(height: 28),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: teamsSection),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: pointsSection),
            ],
          )
        else ...[
          teamsSection,
          const SizedBox(height: 28),
          pointsSection,
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.type,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.onProfile,
  });

  final String name;
  final String type;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(radius: 26, child: Text(name.isEmpty ? '?' : name[0].toUpperCase())),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(label: Text(type)),
                      Chip(label: Text(isActive ? 'Active' : 'Inactive')),
                      if (startDate != null || endDate != null)
                        Chip(label: Text(_dateRange(startDate, endDate))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onProfile,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Tournament Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.teamCount, required this.isActive, required this.tournamentType});

  final int teamCount;
  final bool isActive;
  final String tournamentType;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(icon: Icons.groups_outlined, label: 'Teams', value: '$teamCount'),
        _SummaryCard(icon: Icons.category_outlined, label: 'Type', value: tournamentType),
        _SummaryCard(icon: Icons.circle_outlined, label: 'Status', value: isActive ? 'Active' : 'Inactive'),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 3),
                    Text(value, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
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

String _dateRange(DateTime? start, DateTime? end) {
  String format(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  if (start != null && end != null) return '${format(start)} – ${format(end)}';
  if (start != null) return 'From ${format(start)}';
  return 'Until ${format(end!)}';
}
