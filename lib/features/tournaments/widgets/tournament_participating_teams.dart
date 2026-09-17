import 'package:flutter/material.dart';

import '../../../domain/teams/models/team.dart';

class TournamentParticipatingTeams extends StatelessWidget {
  const TournamentParticipatingTeams({
    required this.teams,
    required this.onRemove,
    required this.onManageSquad,
    super.key,
  });

  final List<Team> teams;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onManageSquad;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.groups_outlined),
          title: Text('No teams selected'),
          subtitle: Text('Select one or more active teams above.'),
        ),
      );
    }

    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: isWide ? _DesktopTable(teams: teams, onRemove: onRemove, onManageSquad: onManageSquad) : _MobileList(teams: teams, onRemove: onRemove, onManageSquad: onManageSquad),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.teams, required this.onRemove, required this.onManageSquad});

  final List<Team> teams;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onManageSquad;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Team')),
          DataColumn(label: Text('Short Name')),
          DataColumn(label: Text('Scope')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          for (final team in teams)
            DataRow(
              cells: [
                DataCell(Text(team.name)),
                DataCell(Text(team.shortName)),
                const DataCell(Text('Global team')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onManageSquad(team.id),
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('Manage Squad'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Remove from tournament',
                        onPressed: () => onRemove(team.id),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  const _MobileList({required this.teams, required this.onRemove, required this.onManageSquad});

  final List<Team> teams;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onManageSquad;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < teams.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(child: Text(teams[i].shortName)),
            title: Text(teams[i].name),
            subtitle: const Text('Global team'),
            trailing: PopupMenuButton<String>(
              tooltip: 'Team actions',
              onSelected: (value) {
                if (value == 'squad') onManageSquad(teams[i].id);
                if (value == 'remove') onRemove(teams[i].id);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'squad', child: Text('Manage Squad')),
                PopupMenuItem(value: 'remove', child: Text('Remove from tournament')),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
