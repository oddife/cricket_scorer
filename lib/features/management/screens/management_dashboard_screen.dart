import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../players/providers/player_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../tournaments/providers/tournament_provider.dart';

class ManagementDashboardScreen extends ConsumerWidget {
  const ManagementDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playerProvider);
    final teams = ref.watch(teamProvider);
    final tournaments = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Management'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(wide ? 32 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cricket Scorer Management',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage global players, teams, tournaments and match data.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    _StatsGrid(
                      wide: wide,
                      stats: [
                        _StatItem(
                          icon: Icons.people_outline,
                          label: 'Players',
                          value: _countText(players),
                        ),
                        _StatItem(
                          icon: Icons.groups_outlined,
                          label: 'Teams',
                          value: _countText(teams),
                        ),
                        _StatItem(
                          icon: Icons.emoji_events_outlined,
                          label: 'Tournaments',
                          value: _countText(tournaments),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Management',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _ManagementGrid(wide: wide),
                    const SizedBox(height: 32),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.sports_cricket_outlined),
                        title: const Text('Matches'),
                        subtitle: const Text(
                          'Open live, recent and recovery match tools.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/matches/recent'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _countText(AsyncValue<List<Object>> value) {
    return value.when(
      data: (items) => '${items.length}',
      loading: () => '—',
      error: (_, __) => '—',
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.wide, required this.stats});

  final bool wide;
  final List<_StatItem> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) => _StatCard(item: stats[index]),
    );
  }
}

class _StatItem {
  const _StatItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(item.icon, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.value, style: Theme.of(context).textTheme.headlineSmall),
                Text(item.label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ManagementItem(
        icon: Icons.people_outline,
        title: 'Players',
        subtitle: 'Manage global player records',
        route: '/players',
      ),
      _ManagementItem(
        icon: Icons.groups_outlined,
        title: 'Teams',
        subtitle: 'Manage teams and global player squads',
        route: '/teams',
      ),
      _ManagementItem(
        icon: Icons.emoji_events_outlined,
        title: 'Tournaments',
        subtitle: 'Manage tournaments, teams and points',
        route: '/tournaments',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 150,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(item.route),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(item.icon, size: 38),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(item.subtitle),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ManagementItem {
  const _ManagementItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
