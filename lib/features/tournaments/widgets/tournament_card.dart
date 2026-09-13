import 'package:flutter/material.dart';

import '../../../domain/tournaments/enums/tournament_type.dart';
import '../../../domain/tournaments/models/tournament.dart';

class TournamentCard extends StatelessWidget {
  const TournamentCard({required this.tournament, required this.onTap, super.key});

  final Tournament tournament;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 28,
            child: tournament.logoPath == null
                ? const Icon(Icons.emoji_events_outlined)
                : const Icon(Icons.image_outlined),
          ),
          title: Text(tournament.name),
          subtitle: Text(tournament.type.label),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}