import 'package:flutter/material.dart';

import '../../../domain/players/models/player.dart';

class TeamSquadTable extends StatelessWidget {
  const TeamSquadTable({
    required this.players,
    required this.onRemove,
    super.key,
  });

  final List<Player> players;
  final Future<void> Function(Player player) onRemove;

  String _battingLabel(BattingStyle style) {
    switch (style) {
      case BattingStyle.right:
        return 'Right';
      case BattingStyle.left:
        return 'Left';
    }
  }

  String _bowlingLabel(BowlingStyle style) {
    switch (style) {
      case BowlingStyle.right:
        return 'Right';
      case BowlingStyle.left:
        return 'Left';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: DataTable(
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Player')),
            DataColumn(label: Text('Jersey')),
            DataColumn(label: Text('Batting')),
            DataColumn(label: Text('Bowling')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: players.map((player) {
            final initials = player.displayName.isEmpty
                ? '?'
                : player.displayName[0].toUpperCase();
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Text(initials),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            player.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(Text(player.jerseyNumber?.toString() ?? '—')),
                DataCell(Text(_battingLabel(player.battingStyle))),
                DataCell(Text(_bowlingLabel(player.bowlingStyle))),
                DataCell(
                  Chip(
                    label: Text(player.isActive ? 'Active' : 'Inactive'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                DataCell(
                  IconButton(
                    tooltip: 'Remove from team',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () => onRemove(player),
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
