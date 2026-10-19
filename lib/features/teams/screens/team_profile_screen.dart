import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/team_player_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/team_logo.dart';

class TeamProfileScreen extends ConsumerWidget {
  const TeamProfileScreen({required this.teamId, super.key});

  final int teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamProvider);
    final members = ref.watch(teamPlayersProvider(teamId));

    return Scaffold(
      appBar: AppBar(title: const Text('Team Profile')),
      body: teams.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load team: $error')),
        data: (items) {
          final matches = items.where((team) => team.id == teamId);
          if (matches.isEmpty) {
            return const Center(child: Text('Team not found'));
          }
          final team = matches.first;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: TeamLogo(
                  teamName: team.name,
                  logoPath: team.logoPath,
                  radius: 64,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  team.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Center(child: Text(team.shortName)),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Short name'),
                      trailing: Text(team.shortName),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('Players'),
                      trailing: members.when(
                        loading: () => const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, _) => const Text('—'),
                        data: (players) => Text(players.length.toString()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: const Text('Statistics'),
                  subtitle: const Text('Team statistics will be derived from matches.'),
                ),
              ),
              const SizedBox(height: 16),
              members.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => Text('Unable to load players: $error'),
                data: (players) {
                  if (players.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.groups_outlined),
                          title: Text('Squad'),
                        ),
                        const Divider(height: 1),
                        ...players.map(
                          (player) => ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                player.displayName.isEmpty
                                    ? '?'
                                    : player.displayName[0].toUpperCase(),
                              ),
                            ),
                            title: Text(player.displayName),
                            subtitle: Text(player.name),
                          ),
                        ),
                      ],
                    ),
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
