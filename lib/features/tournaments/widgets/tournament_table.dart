import 'package:flutter/material.dart';

import '../../../domain/tournaments/models/tournament.dart';

class TournamentTable extends StatelessWidget {
  const TournamentTable({
    required this.tournaments,
    required this.onOpen,
    required this.onManage,
    required this.onEdit,
    required this.onDeactivate,
    super.key,
  });

  final List<Tournament> tournaments;
  final ValueChanged<Tournament> onOpen;
  final ValueChanged<Tournament> onManage;
  final ValueChanged<Tournament> onEdit;
  final ValueChanged<Tournament> onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Tournament')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Dates')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: tournaments.map((tournament) {
            return DataRow(
              onSelectChanged: (_) => onOpen(tournament),
              cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
                    child: Text(
                      tournament.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(Text(_typeLabel(tournament))),
                DataCell(Text(_dateLabel(context, tournament))),
                DataCell(_StatusChip(isActive: tournament.isActive)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Manage Teams',
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => onManage(tournament),
                      ),
                      IconButton(
                        tooltip: 'Edit Tournament',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(tournament),
                      ),
                      if (tournament.isActive)
                        IconButton(
                          tooltip: 'Deactivate Tournament',
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () => onDeactivate(tournament),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _typeLabel(Tournament tournament) {
    switch (tournament.type.toString().split('.').last) {
      case 'league':
        return 'League';
      case 'knockout':
        return 'Knockout';
      case 'leagueAndKnockout':
        return 'League + Knockout';
      default:
        return tournament.type.toString();
    }
  }

  static String _dateLabel(BuildContext context, Tournament tournament) {
    final start = tournament.startDate;
    final end = tournament.endDate;
    final format = MaterialLocalizations.of(context);

    if (start == null && end == null) return '—';
    if (start != null && end != null) {
      return '${format.formatMediumDate(start)} – ${format.formatMediumDate(end)}';
    }
    if (start != null) return 'From ${format.formatMediumDate(start)}';
    return 'Until ${format.formatMediumDate(end!)}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
        size: 16,
      ),
      label: Text(isActive ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
    );
  }
}
