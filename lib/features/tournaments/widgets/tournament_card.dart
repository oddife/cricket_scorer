import 'package:flutter/material.dart';

import '../../../domain/tournaments/models/tournament.dart';
import 'tournament_logo.dart';

class TournamentCard extends StatelessWidget {
  const TournamentCard({
    required this.tournament,
    required this.onTap,
    this.onManage,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final Tournament tournament;
  final VoidCallback onTap;
  final VoidCallback? onManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: TournamentLogo(
          tournamentName: tournament.name,
          logoPath: tournament.logoPath,
        ),
        title: Text(tournament.name),
        subtitle: Text(_typeLabel(tournament.type)),
        onTap: onTap,
        trailing: (onManage == null && onEdit == null && onDelete == null)
            ? const Icon(Icons.chevron_right)
            : PopupMenuButton<String>(
                tooltip: 'Tournament management',
                onSelected: (value) {
                  if (value == 'manage') onManage?.call();
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onManage != null)
                    const PopupMenuItem(
                      value: 'manage',
                      child: ListTile(
                        leading: Icon(Icons.settings_outlined),
                        title: Text('Manage Teams'),
                      ),
                    ),
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit Tournament'),
                      ),
                    ),
                  if (onDelete != null)
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

  static String _typeLabel(dynamic type) {
    switch (type.toString().split('.').last) {
      case 'league': return 'League';
      case 'knockout': return 'Knockout';
      case 'leagueAndKnockout': return 'League + Knockout';
      default: return type.toString();
    }
  }
}
