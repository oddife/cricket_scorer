import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../players/providers/player_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../tournaments/providers/tournament_provider.dart';

class ManagementDashboard extends ConsumerWidget {
  const ManagementDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playerProvider);
    final teams = ref.watch(teamProvider);
    final tournaments = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Scorer Management'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Management', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Global players, teams, tournaments and match administration.'),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 800 ? 3 : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: columns == 1 ? 3.2 : 2.0,
                      children: [
                        _StatCard(icon: Icons.people_outline, label: 'Players', value: _count(players)),
                        _StatCard(icon: Icons.groups_outlined, label: 'Teams', value: _count(teams)),
                        _StatCard(icon: Icons.emoji_events_outlined, label: 'Tournaments', value: _count(tournaments)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text('Manage', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 800 ? 3 : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: columns == 1 ? 3.0 : 1.8,
                      children: [
                        _ActionCard(icon: Icons.people_outline, title: 'Players', subtitle: 'Global player records', route: '/players'),
                        _ActionCard(icon: Icons.groups_outlined, title: 'Teams', subtitle: 'Teams and squad membership', route: '/teams'),
                        _ActionCard(icon: Icons.emoji_events_outlined, title: 'Tournaments', subtitle: 'Teams and points rules', route: '/tournaments'),
                        _ActionCard(icon: Icons.live_tv_outlined, title: 'Live Matches', subtitle: 'Open the current scoring matches', route: '/matches/live'),
                        _ActionCard(icon: Icons.history, title: 'Recent Matches', subtitle: 'Results and scorecards', route: '/matches/recent'),
                        _ActionCard(icon: Icons.cloud_download_outlined, title: 'Recovery', subtitle: 'Restore synchronized matches', route: '/matches/recovery'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _count<T>(AsyncValue<List<T>> value) => value.when(
        data: (items) => '${items.length}',
        loading: () => '—',
        error: (_, _) => '—',
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 34),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.route});
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
}
