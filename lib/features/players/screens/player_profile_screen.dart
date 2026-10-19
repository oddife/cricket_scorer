import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/players/player_statistics_service.dart';
import '../../../core/database/database_provider.dart';
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
          final statistics = PlayerStatisticsService(
            matchRepository: ref.read(matchRepositoryProvider),
            inningsRepository: ref.read(inningsRepositoryProvider),
            ballEventRepository: ref.read(ballEventRepositoryProvider),
          ).load(playerId);

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
              FutureBuilder<PlayerStatistics>(
                future: statistics,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: const Text('Statistics unavailable'),
                        subtitle: Text('${snapshot.error}'),
                      ),
                    );
                  }

                  final stats = snapshot.data!;
                  return Column(
                    children: [
                      _StatsCard(
                        title: 'Career batting',
                        icon: Icons.sports_cricket_outlined,
                        children: [
                          _StatTile('Matches', '${stats.matches}'),
                          _StatTile('Innings', '${stats.battingInnings}'),
                          _StatTile('Runs', '${stats.runs}'),
                          _StatTile('Balls', '${stats.ballsFaced}'),
                          _StatTile('4s', '${stats.fours}'),
                          _StatTile('6s', '${stats.sixes}'),
                          _StatTile(
                            'Average',
                            stats.battingAverage.toStringAsFixed(2),
                          ),
                          _StatTile(
                            'Strike rate',
                            stats.strikeRate.toStringAsFixed(2),
                          ),
                          _StatTile('Dismissals', '${stats.dismissals}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatsCard(
                        title: 'Career bowling',
                        icon: Icons.sports_baseball_outlined,
                        children: [
                          _StatTile('Innings', '${stats.bowlingInnings}'),
                          _StatTile('Overs', stats.oversBowled),
                          _StatTile('Runs conceded', '${stats.runsConceded}'),
                          _StatTile('Wickets', '${stats.wickets}'),
                          _StatTile(
                            'Economy',
                            stats.economyRate.toStringAsFixed(2),
                          ),
                          _StatTile('Wides', '${stats.wides}'),
                          _StatTile('No-balls', '${stats.noBalls}'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              leading: Icon(icon),
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
