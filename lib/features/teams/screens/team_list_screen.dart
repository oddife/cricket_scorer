import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/management/permanent_delete_service.dart';
import '../../../domain/teams/models/team.dart';
import '../providers/team_provider.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/edit_team_dialog.dart';
import '../widgets/team_logo.dart';

class TeamListScreen extends ConsumerStatefulWidget {
  const TeamListScreen({super.key});

  @override
  ConsumerState<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends ConsumerState<TeamListScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addTeam() async {
    await showAddTeamDialog(context, ref);
  }

  Future<void> _deleteTeam(Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team permanently?'),
        content: Text(
          'Permanently delete “${team.name}”, its squad memberships and '
          'tournament memberships?\n\nTeams referenced by match history cannot '
          'be deleted.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(permanentDeleteServiceProvider).deleteTeam(team.id);
      ref.invalidate(teamProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team permanently deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete team: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamProvider);
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: FilledButton.icon(
                  onPressed: _addTeam,
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Add Team'),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: _addTeam,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Add Team'),
            ),
      body: teams.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load teams: $error')),
        data: (items) {
          final activeCount = items.where((team) => team.isActive).length;
          final inactiveCount = items.length - activeCount;
          final query = _search.toLowerCase();
          final filtered = items.where((team) {
            if (!_showInactive && !team.isActive) return false;
            if (query.isEmpty) return true;
            return team.name.toLowerCase().contains(query) ||
                team.shortName.toLowerCase().contains(query);
          }).toList(growable: false);

          return Column(
            children: [
              if (wide)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      children: [
                        _SummaryCard(
                          icon: Icons.groups_outlined,
                          label: 'Total Teams',
                          value: items.length.toString(),
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          icon: Icons.check_circle_outline,
                          label: 'Active',
                          value: activeCount.toString(),
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          icon: Icons.archive_outlined,
                          label: 'Inactive',
                          value: inactiveCount.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 16, wide ? 24 : 16, 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _search = value.trim()),
                          decoration: InputDecoration(
                            labelText: 'Search teams',
                            hintText: 'Team name or short name',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _search = '');
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: Text('Inactive ($inactiveCount)'),
                        selected: _showInactive,
                        onSelected: (value) =>
                            setState(() => _showInactive = value),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          items.isEmpty
                              ? 'No teams yet. Add your first team.'
                              : 'No teams match your search.',
                        ),
                      )
                    : wide
                        ? _TeamTable(
                            teams: filtered,
                            onManage: (team) =>
                                context.push('/teams/${team.id}/manage'),
                            onEdit: (team) =>
                                showEditTeamDialog(context, ref, team),
                            onDeactivate: (team) => ref
                                .read(teamProvider.notifier)
                                .deactivate(team.id),
                            onDelete: _deleteTeam,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final team = filtered[index];
                              return _TeamCard(
                                team: team,
                                onTap: () =>
                                    context.push('/teams/${team.id}'),
                                onManage: () => context
                                    .push('/teams/${team.id}/manage'),
                                onEdit: () =>
                                    showEditTeamDialog(context, ref, team),
                                onDeactivate: () => ref
                                    .read(teamProvider.notifier)
                                    .deactivate(team.id),
                                onDelete: () => _deleteTeam(team),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamTable extends StatelessWidget {
  const _TeamTable({
    required this.teams,
    required this.onManage,
    required this.onEdit,
    required this.onDeactivate,
    required this.onDelete,
  });

  final List<Team> teams;
  final Future<void> Function(Team team) onManage;
  final Future<void> Function(Team team) onEdit;
  final Future<void> Function(Team team) onDeactivate;
  final Future<void> Function(Team team) onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: DataTable(
              columnSpacing: 36,
              columns: const [
                DataColumn(label: Text('Team')),
                DataColumn(label: Text('Short Name')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: teams.map((team) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TeamLogo(
                            teamName: team.name,
                            logoPath: team.logoPath,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            team.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(team.shortName)),
                    DataCell(
                      Chip(
                        label: Text(team.isActive ? 'Active' : 'Inactive'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () => onManage(team),
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Manage Squad'),
                          ),
                          IconButton(
                            tooltip: 'Edit team',
                            onPressed: () => onEdit(team),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Deactivate team',
                            onPressed: team.isActive
                                ? () => onDeactivate(team)
                                : null,
                            icon: const Icon(Icons.archive_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete permanently',
                            onPressed: () => onDelete(team),
                            icon: Icon(
                              Icons.delete_forever_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.onTap,
    required this.onManage,
    required this.onEdit,
    required this.onDeactivate,
    required this.onDelete,
  });

  final Team team;
  final VoidCallback onTap;
  final VoidCallback onManage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: TeamLogo(teamName: team.name, logoPath: team.logoPath),
        title: Text(team.name),
        subtitle: Text(team.shortName),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          tooltip: 'Team management',
          onSelected: (value) {
            switch (value) {
              case 'manage':
                onManage();
              case 'edit':
                onEdit();
              case 'deactivate':
                onDeactivate();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'manage',
              child: ListTile(
                leading: Icon(Icons.groups_outlined),
                title: Text('Manage Team'),
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit Team'),
              ),
            ),
            if (team.isActive)
              const PopupMenuItem(
                value: 'deactivate',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Deactivate Team'),
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Delete Permanently'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
