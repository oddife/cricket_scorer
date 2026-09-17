import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/models/match.dart';
import '../../matches/providers/match_provider.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Scorer'),
        actions: [
          IconButton(
            tooltip: 'Management',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => context.push('/admin'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeHeader(colors: colors),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 680) {
                        return Column(
                          children: [
                            _PrimaryActionCard(
                              icon: Icons.sports_cricket_outlined,
                              title: 'Start a Match',
                              subtitle: 'Set up teams, players and scoring rules',
                              onTap: () => context.push('/matches/normal/new'),
                              colors: colors,
                            ),
                            const SizedBox(height: 12),
                            _PrimaryActionCard(
                              icon: Icons.emoji_events_outlined,
                              title: 'Tournament',
                              subtitle: 'Create or manage your competitions',
                              onTap: () => context.push('/tournaments'),
                              colors: colors,
                              secondary: true,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _PrimaryActionCard(
                              icon: Icons.sports_cricket_outlined,
                              title: 'Start a Match',
                              subtitle: 'Set up teams, players and scoring rules',
                              onTap: () => context.push('/matches/normal/new'),
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PrimaryActionCard(
                              icon: Icons.emoji_events_outlined,
                              title: 'Tournament',
                              subtitle: 'Create or manage your competitions',
                              onTap: () => context.push('/tournaments'),
                              colors: colors,
                              secondary: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Match Centre',
                    subtitle: 'Everything happening around your matches',
                  ),
                  const SizedBox(height: 12),
                  _MatchCentre(
                    matchesAsync: matchesAsync,
                    colors: colors,
                  ),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Management',
                    subtitle: 'Keep your cricket data organised',
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 700;
                      final cards = [
                        _ManagementCard(
                          icon: Icons.people_outline,
                          title: 'Players',
                          subtitle: 'Manage global players',
                          onTap: () => context.push('/players'),
                          colors: colors,
                        ),
                        _ManagementCard(
                          icon: Icons.groups_outlined,
                          title: 'Teams',
                          subtitle: 'Manage global teams',
                          onTap: () => context.push('/teams'),
                          colors: colors,
                        ),
                        _ManagementCard(
                          icon: Icons.emoji_events_outlined,
                          title: 'Tournaments',
                          subtitle: 'Manage competitions',
                          onTap: () => context.push('/tournaments'),
                          colors: colors,
                        ),
                        _ManagementCard(
                          icon: Icons.dashboard_outlined,
                          title: 'Dashboard',
                          subtitle: 'Match and admin operations',
                          onTap: () => context.push('/admin'),
                          colors: colors,
                        ),
                      ];
                      if (compact) {
                        return Column(
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              cards[i],
                              if (i < cards.length - 1) const SizedBox(height: 10),
                            ],
                          ],
                        );
                      }
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3.4,
                        children: cards,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            colors.surfaceContainerHighest,
          ],
        ),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.sports_cricket, color: colors.onPrimary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cricket Scorer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Score matches, manage teams and keep every game organised.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
    this.secondary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colors;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final background = secondary ? colors.surfaceContainerHigh : colors.primary;
    final foreground = secondary ? colors.onSurface : colors.onPrimary;
    final secondaryText = secondary
        ? colors.onSurfaceVariant
        : colors.onPrimary.withValues(alpha: .82);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: foreground, size: 29),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: secondaryText)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCentre extends StatelessWidget {
  const _MatchCentre({required this.matchesAsync, required this.colors});

  final AsyncValue<List<Match>> matchesAsync;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return matchesAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Unable to load matches: $error'),
        ),
      ),
      data: (items) {
        final liveMatches = items
            .where((match) => match.status == MatchStatus.live)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final live = _LiveMatchesCard(
              matches: liveMatches,
              colors: colors,
            );
            final recent = _QuickMatchCard(
              icon: Icons.history_rounded,
              title: 'Recent Matches',
              subtitle: 'Completed matches, scorecards and PDF exports',
              onTap: () => context.push('/matches/recent'),
              colors: colors,
            );
            final recover = _QuickMatchCard(
              icon: Icons.cloud_download_outlined,
              title: 'Recover Match',
              subtitle: 'Restore a synchronized match into local storage',
              onTap: () => context.push('/matches/recovery'),
              colors: colors,
            );

            if (compact) {
              return Column(
                children: [
                  live,
                  const SizedBox(height: 10),
                  recent,
                  const SizedBox(height: 10),
                  recover,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: live),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      recent,
                      const SizedBox(height: 12),
                      recover,
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LiveMatchesCard extends StatelessWidget {
  const _LiveMatchesCard({required this.matches, required this.colors});

  final List<Match> matches;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/matches/normal/new'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.live_tv_outlined),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No live matches',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Start a match when you are ready to score.'),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      );
    }

    final visible = matches.take(3).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: colors.error),
                const SizedBox(width: 8),
                Text(
                  'LIVE NOW',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                ),
                const Spacer(),
                if (matches.length > visible.length)
                  TextButton(
                    onPressed: () => context.push('/matches/live'),
                    child: Text('View all ${matches.length}'),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: const Icon(Icons.sports_cricket_outlined),
              ),
              title: Text(
                visible[i].name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${visible[i].oversPerInnings} overs  •  ${visible[i].inningsCount} innings',
              ),
              trailing: FilledButton.tonal(
                onPressed: () => context.push('/matches/${visible[i].id}/live'),
                child: const Text('Open'),
              ),
              onTap: () => context.push('/matches/${visible[i].id}/live'),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickMatchCard extends StatelessWidget {
  const _QuickMatchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 28, color: colors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.onPrimaryContainer, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
