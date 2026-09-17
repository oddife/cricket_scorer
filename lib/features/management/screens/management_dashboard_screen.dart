import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/models/match.dart';
import '../../matches/providers/match_provider.dart';
import '../../players/providers/player_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../tournaments/providers/tournament_provider.dart';

class ManagementDashboardScreen extends ConsumerStatefulWidget {
  const ManagementDashboardScreen({super.key});

  @override
  ConsumerState<ManagementDashboardScreen> createState() => _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends ConsumerState<ManagementDashboardScreen> {
  @override
  void initState() {
    super.initState();
    ref.invalidate(playerProvider);
    ref.invalidate(teamProvider);
    ref.invalidate(tournamentProvider);
    ref.invalidate(matchProvider);
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playerProvider);
    final teams = ref.watch(teamProvider);
    final tournaments = ref.watch(tournamentProvider);
    final matches = ref.watch(matchProvider);
    final liveCount = matches.maybeWhen(data: (items) => items.where((m) => m.status == MatchStatus.live).length, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(playerProvider);
              ref.invalidate(teamProvider);
              ref.invalidate(tournamentProvider);
              ref.invalidate(matchProvider);
            },
          ),
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
                    Text('Cricket Scorer Management', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('Manage global players, teams, tournaments and match data.', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 28),
                    _StatsGrid(
                      wide: wide,
                      stats: [
                        _StatItem(icon: Icons.people_outline, label: 'Players', value: _countText(players)),
                        _StatItem(icon: Icons.groups_outlined, label: 'Teams', value: _countText(teams)),
                        _StatItem(icon: Icons.emoji_events_outlined, label: 'Tournaments', value: _countText(tournaments)),
                        _StatItem(icon: Icons.live_tv_outlined, label: 'Live Matches', value: '$liveCount'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Management', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _ManagementGrid(wide: wide),
                    const SizedBox(height: 32),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.sports_cricket_outlined),
                        title: const Text('Match Operations'),
                        subtitle: const Text('Open live, recent and recovery match tools.'),
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

  String _countText<T>(AsyncValue<List<T>> value) {
    return value.when(
      data: (items) => '${items.length}',
      loading: () => '—',
      error: (_, _) => '—',
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.wide, required this.stats});
  final bool wide;
  final List<_StatItem> stats;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: wide ? 4 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 112,
        ),
        itemBuilder: (context, index) => _StatCard(item: stats[index]),
      );
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
  Widget build(BuildContext context) => Card(
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

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ManagementItem(icon: Icons.people_outline, title: 'Players', subtitle: 'Manage global player records', route: '/players'),
      _ManagementItem(icon: Icons.groups_outlined, title: 'Teams', subtitle: 'Manage teams and global player squads', route: '/teams'),
      _ManagementItem(icon: Icons.emoji_events_outlined, title: 'Tournaments', subtitle: 'Manage tournaments, teams and points', route: '/tournaments'),
      _ManagementItem(icon: Icons.live_tv_outlined, title: 'Live Matches', subtitle: 'Open current scoring matches', route: '/matches/live'),
      _ManagementItem(icon: Icons.history, title: 'Recent Matches', subtitle: 'Results and scorecards', route: '/matches/recent'),
      _ManagementItem(icon: Icons.cloud_download_outlined, title: 'Recovery', subtitle: 'Restore synchronized matches', route: '/matches/recovery'),
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
  const _ManagementItem({required this.icon, required this.title, required this.subtitle, required this.route});
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
