import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/models/match.dart';
import '../../matches/providers/match_provider.dart';
import '../../players/screens/player_list_screen.dart';
import '../../teams/screens/team_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.invalidate(matchProvider);
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Scorer'),
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
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cricket Scorer',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a tournament or start a normal match',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, c) {
                    final cards = [
                      _ActionCard(
                        icon: Icons.emoji_events_outlined,
                        title: 'Tournament',
                        subtitle: 'Create or manage tournaments',
                        onTap: () => context.push('/tournaments'),
                      ),
                      _ActionCard(
                        icon: Icons.sports_cricket,
                        title: 'Normal Match',
                        subtitle: 'Start a standalone match',
                        onTap: () => context.push('/matches/normal/new'),
                      ),
                    ];
                    return c.maxWidth < 600
                        ? Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 16),
                              cards[1],
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 40),
                _Section(
                  title: 'Matches',
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cards = [
                        _ActionCard(
                          icon: Icons.live_tv_outlined,
                          title: 'Live Matches',
                          subtitle: 'Open matches that are currently live',
                          onTap: () => context.push('/matches/live'),
                        ),
                        _ActionCard(
                          icon: Icons.history,
                          title: 'Recent Matches',
                          subtitle:
                              'Open completed and previous matches, scorecards, and PDF exports',
                          onTap: () => context.push('/matches/recent'),
                        ),
                        _ActionCard(
                          icon: Icons.cloud_download_outlined,
                          title: 'Recover Match',
                          subtitle:
                              'Find synchronized matches and restore one into local SQLite',
                          onTap: () => context.push('/matches/recovery'),
                        ),
                      ];
                      return c.maxWidth < 600
                          ? Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 16),
                                cards[1],
                                const SizedBox(height: 16),
                                cards[2],
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[1]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[2]),
                              ],
                            );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                _Section(
                  title: 'Live Matches',
                  child: _LiveMatchesPreview(matchesAsync: matchesAsync),
                ),
                const SizedBox(height: 32),
                _Section(
                  title: 'Management',
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cards = [
                        _ActionCard(
                          icon: Icons.groups_outlined,
                          title: 'Teams',
                          subtitle: 'Manage global teams',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TeamListScreen(),
                            ),
                          ),
                        ),
                        _ActionCard(
                          icon: Icons.people_outline,
                          title: 'Players',
                          subtitle: 'Manage global players',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlayerListScreen(),
                            ),
                          ),
                        ),
                      ];
                      return c.maxWidth < 600
                          ? Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 16),
                                cards[1],
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[1]),
                              ],
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveMatchesPreview extends StatelessWidget {
  const _LiveMatchesPreview({required this.matchesAsync});

  final AsyncValue<List<Match>> matchesAsync;

  @override
  Widget build(BuildContext context) {
    return matchesAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load live matches: $error'),
        ),
      ),
      data: (items) {
        final liveMatches = items
            .where((match) => match.status == MatchStatus.live)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (liveMatches.isEmpty) {
          return const _EmptyState(
            icon: Icons.live_tv_outlined,
            message: 'No live matches',
          );
        }

        final visible = liveMatches.take(3).toList();
        return Card(
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.live_tv_outlined),
                  title: Text(visible[i].name),
                  subtitle: Text(
                    '${visible[i].oversPerInnings} overs  •  ${visible[i].inningsCount} innings',
                  ),
                  trailing: FilledButton(
                    onPressed: () => context.push(
                      '/matches/${visible[i].id}/live',
                    ),
                    child: const Text('Open'),
                  ),
                  onTap: () => context.push(
                    '/matches/${visible[i].id}/live',
                  ),
                ),
              ],
              if (liveMatches.length > visible.length)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.push('/matches/live'),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('View all ${liveMatches.length} live matches'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(icon, size: 40),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 8),
                Text(message),
              ],
            ),
          ),
        ),
      );
}
