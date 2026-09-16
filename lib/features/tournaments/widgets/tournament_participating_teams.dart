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

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < teams.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(child: Text(teams[i].shortName)),
              title: Text(teams[i].name),
              subtitle: const Text('Global team'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onManageSquad(teams[i].id),
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('Manage Squad'),
                  ),
                  IconButton(
                    tooltip: 'Remove team',
                    onPressed: () => onRemove(teams[i].id),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
