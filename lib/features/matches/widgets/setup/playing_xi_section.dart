import 'package:flutter/material.dart';

class PlayingXiSection extends StatelessWidget {
  const PlayingXiSection({
    super.key,
    required this.teamAName,
    required this.teamBName,
    required this.playersPerTeam,
  });

  final String teamAName;
  final String teamBName;
  final int playersPerTeam;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline),
                const SizedBox(width: 10),
                Text('Playing XI', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select $playersPerTeam players for each team and set their batting order.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _TeamPlaceholder(teamName: teamAName),
            const SizedBox(height: 12),
            _TeamPlaceholder(teamName: teamBName),
          ],
        ),
      ),
    );
  }
}

class _TeamPlaceholder extends StatelessWidget {
  const _TeamPlaceholder({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(teamName)),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Select Players'),
          ),
        ],
      ),
    );
  }
}
