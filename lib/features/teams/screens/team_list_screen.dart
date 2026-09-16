import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          final query = _search.toLowerCase();
          final filtered = items.where((team) {
            if (!_showInactive && !team.isActive) return false;
            if (query.isEmpty) return true;
            return team.name.toLowerCase().contains(query) ||
                team.shortName.toLowerCase().contains(query);
          }).toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _search = value.trim()),
                        decoration: const InputDecoration(
                          labelText: 'Search teams',
                          hintText: 'Team name or short name',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Show inactive'),
                      selected: _showInactive,
                      onSelected: (value) =>
                          setState(() => _showInactive = value),
                    ),
                  ],
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
                            onDeactivate: (team) =>
                                ref.read(teamProvider.notifier).deactivate(team.id),
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

class _TeamTable extends StatelessWidget {
  const _TeamTable({
    required this.teams,
    required this.onManage,
    required this.onEdit,
    required this.onDeactivate,
  });

  final List<Team> teams;
  final Future<void> Function(Team team) onManage;
  final Future<void> Function(Team team) onEdit;
  final Future<void> Function(Team team) onDeactivate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: DataTable(
          columnSpacing: 32,
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
                    ],
                  ),
                ),
              ],
            );
          }).toList(growable: false),
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
  });

  final Team team;
  final VoidCallback onTap;
  final VoidCallback onManage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

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
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'manage',
              child: ListTile(
                leading: Icon(Icons.groups_outlined),
                title: Text('Manage Team'),
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit Team'),
              ),
            ),
            PopupMenuItem(
              value: 'deactivate',
              child: ListTile(
                leading: Icon(Icons.archive_outlined),
                title: Text('Deactivate Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
