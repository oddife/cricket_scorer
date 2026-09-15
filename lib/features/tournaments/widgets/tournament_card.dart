import 'package:flutter/material.dart';

import '../../../domain/tournaments/models/tournament.dart';
import 'tournament_logo.dart';

class TournamentCard extends StatelessWidget {
  const TournamentCard({
    required this.tournament,
    required this.onTap,
    this.onManage,
    super.key,
  });

  final Tournament tournament;
  final VoidCallback onTap;
  final VoidCallback? onManage;

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
        subtitle: Text(tournament.type.label),
        onTap: onTap,
        trailing: onManage == null
            ? const Icon(Icons.chevron_right)
            : PopupMenuButton<String>(
                tooltip: 'Tournament management',
                onSelected: (value) {
                  if (value == 'manage') onManage!();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'manage',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit Tournament'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
