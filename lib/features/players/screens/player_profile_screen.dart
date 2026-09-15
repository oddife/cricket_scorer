import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';
import '../widgets/player_avatar.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key, required this.playerId});

  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Player Profile')),
      body: players.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load player: $error')),
        data: (items) {
          final matches = items.where((player) => player.id == playerId);
          if (matches.isEmpty) {
            return const Center(child: Text('Player not found'));
          }

          final player = matches.first;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: PlayerAvatar(
                  displayName: player.displayName,
                  photoPath: player.photoPath,
                  radius: 64,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  player.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              if (player.name != player.displayName) ...[
                const SizedBox(height: 4),
                Center(child: Text(player.name)),
              ],
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.numbers),
                      title: const Text('Jersey number'),
                      trailing: Text(player.jerseyNumber?.toString() ?? '—'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sports_cricket_outlined),
                      title: const Text('Batting style'),
                      trailing: Text(player.battingStyle.label),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sports_baseball_outlined),
                      title: const Text('Bowling style'),
                      trailing: Text(player.bowlingStyle.label),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: const Text('Statistics'),
                  subtitle: const Text('Match statistics will be derived from ball events.'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
