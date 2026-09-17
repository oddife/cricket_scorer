import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/models/match.dart';
import '../../matches/providers/match_provider.dart';

class _DashboardPalette {
  static const background = Color(0xFF0A0F0B);
  static const appBar = Color(0xFF0C160E);
  static const heroStart = Color(0xFF124C20);
  static const heroEnd = Color(0xFF202821);
  static const card = Color(0xFF151B16);
  static const cardRaised = Color(0xFF1C221D);
  static const cardIcon = Color(0xFF303831);
  static const mint = Color(0xFF9BD792);
  static const green = Color(0xFF2F7D3A);
  static const text = Color(0xFFF2F5F1);
  static const muted = Color(0xFFB7C0B8);
}

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
      backgroundColor: _DashboardPalette.background,
      appBar: AppBar(
        backgroundColor: _DashboardPalette.appBar,
        foregroundColor: _DashboardPalette.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ThemeLogo(size: 42, tint: _DashboardPalette.mint),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'New Castle Cricket Scorer',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
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
            constraints: const BoxConstraints(maxWidth: 1240),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _WelcomeHeader(),
                  const SizedBox(height: 24),
                  _PrimaryActions(),
                  const SizedBox(height: 34),
                  const _SectionHeader(
                    title: 'Match Centre',
                    subtitle: 'Everything happening around your matches',
                  ),
                  const SizedBox(height: 12),
                  _MatchCentre(matchesAsync: matchesAsync),
                  const SizedBox(height: 34),
                  const _SectionHeader(
                    title: 'Management',
                    subtitle: 'Keep your cricket data organised',
                  ),
                  const SizedBox(height: 12),
                  const _ManagementGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeLogo extends StatelessWidget {
  const _ThemeLogo({required this.size, this.tint});

  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final image = SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/branding/logo_nobg.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.sports_cricket,
          color: tint ?? _DashboardPalette.mint,
          size: size * .72,
        ),
      ),
    );
    if (tint == null) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint!, BlendMode.srcIn),
      child: image,
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 198),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_DashboardPalette.heroStart, _DashboardPalette.heroEnd],
        ),
        border: Border.all(
          color: _DashboardPalette.green.withValues(alpha: .55),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final logoSize = compact ? 88.0 : 160.0;
          return Row(
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(compact ? 18 : 24),
                ),
                child: _ThemeLogo(
                  size: compact ? 78 : 150,
                  tint: _DashboardPalette.mint,
                ),
              ),
              SizedBox(width: compact ? 18 : 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New Castle',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: _DashboardPalette.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.8,
                          ),
                    ),
                    Text(
                      'Cricket Scorer',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _DashboardPalette.mint,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.4,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Score matches, manage teams and keep every game organised.',
                      style: TextStyle(
                        color: _DashboardPalette.text,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final start = _PrimaryActionCard(
          icon: Icons.sports_cricket_outlined,
          title: 'Start a Match',
          subtitle: 'Set up teams, players and scoring rules',
          onTap: () => context.push('/matches/normal/new'),
          primary: true,
        );
        final tournament = _PrimaryActionCard(
          icon: Icons.emoji_events_outlined,
          title: 'Tournament',
          subtitle: 'Create or manage your competitions',
          onTap: () => context.push('/tournaments'),
        );
        if (constraints.maxWidth < 700) {
          return Column(
            children: [start, const SizedBox(height: 12), tournament],
          );
        }
        return Row(
          children: [
            Expanded(child: start),
            const SizedBox(width: 16),
            Expanded(child: tournament),
          ],
        );
      },
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? _DashboardPalette.mint
        : _DashboardPalette.cardRaised;
    final foreground = primary
        ? const Color(0xFF102A15)
        : _DashboardPalette.text;
    final secondaryText = primary
        ? const Color(0xFF31563A)
        : _DashboardPalette.muted;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.black.withValues(alpha: .08)
                      : _DashboardPalette.cardIcon,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: foreground, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: foreground, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCentre extends StatelessWidget {
  const _MatchCentre({required this.matchesAsync});

  final AsyncValue<List<Match>> matchesAsync;

  @override
  Widget build(BuildContext context) {
    return matchesAsync.when(
      loading: () => const _DarkCard(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => _DarkCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Unable to load matches: $error',
            style: const TextStyle(color: _DashboardPalette.text),
          ),
        ),
      ),
      data: (items) {
        final liveMatches = items
            .where((match) => match.status == MatchStatus.live)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return LayoutBuilder(
          builder: (context, constraints) {
            final live = _LiveMatchesCard(matches: liveMatches);
            final recent = _QuickMatchCard(
              icon: Icons.history_rounded,
              title: 'Recent Matches',
              subtitle: 'Completed matches, scorecards and PDF exports',
              onTap: () => context.push('/matches/recent'),
            );
            final recover = _QuickMatchCard(
              icon: Icons.cloud_download_outlined,
              title: 'Recover Match',
              subtitle: 'Restore a synchronized match into local storage',
              onTap: () => context.push('/matches/recovery'),
            );
            if (constraints.maxWidth < 760) {
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
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [recent, const SizedBox(height: 12), recover],
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
  const _LiveMatchesCard({required this.matches});

  final List<Match> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return _DarkCard(
        onTap: () => context.push('/matches/normal/new'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const _IconBox(icon: Icons.sports_cricket_outlined),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No live matches',
                      style: TextStyle(
                        color: _DashboardPalette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Start a new match to see it here while scoring.',
                      style: TextStyle(
                        color: _DashboardPalette.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: _DashboardPalette.text),
            ],
          ),
        ),
      );
    }

    return _DarkCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_checked,
                    color: _DashboardPalette.mint, size: 18),
                const SizedBox(width: 8),
                const Text('Live now',
                    style: TextStyle(
                        color: _DashboardPalette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${matches.length}',
                    style: const TextStyle(
                        color: _DashboardPalette.muted,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < matches.length; i++) ...[
              _LiveMatchRow(match: matches[i]),
              if (i < matches.length - 1)
                const Divider(height: 24, color: Color(0xFF2A312B)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveMatchRow extends StatelessWidget {
  const _LiveMatchRow({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/matches/${match.id}/score'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.name,
                      style: const TextStyle(
                          color: _DashboardPalette.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${match.oversPerInnings} overs  •  ${match.inningsCount} innings',
                      style: const TextStyle(color: _DashboardPalette.muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('Continue',
                style: TextStyle(
                    color: _DashboardPalette.mint,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded,
                color: _DashboardPalette.mint, size: 20),
          ],
        ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _DashboardPalette.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _DashboardPalette.muted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: _DashboardPalette.text),
          ],
        ),
      ),
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid();

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ManagementCard(
        icon: Icons.people_outline,
        title: 'Players',
        subtitle: 'Manage global players',
        onTap: () => context.push('/players'),
      ),
      _ManagementCard(
        icon: Icons.groups_outlined,
        title: 'Teams',
        subtitle: 'Manage global teams',
        onTap: () => context.push('/teams'),
      ),
      _ManagementCard(
        icon: Icons.emoji_events_outlined,
        title: 'Tournaments',
        subtitle: 'Manage competitions',
        onTap: () => context.push('/tournaments'),
      ),
      _ManagementCard(
        icon: Icons.dashboard_outlined,
        title: 'Dashboard',
        subtitle: 'Match and admin operations',
        onTap: () => context.push('/admin'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
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
          crossAxisSpacing: 14,
          mainAxisSpacing: 12,
          childAspectRatio: 3.3,
          children: cards,
        );
      },
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
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
  Widget build(BuildContext context) {
    return _DarkCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _DashboardPalette.green.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _DashboardPalette.mint, size: 25),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _DashboardPalette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _DashboardPalette.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _DashboardPalette.text,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _DashboardPalette.cardIcon,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: _DashboardPalette.mint, size: 27),
    );
  }
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .035)),
      ),
      child: Material(
        color: _DashboardPalette.card,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? child
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: child,
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
        Text(title,
            style: const TextStyle(
                color: _DashboardPalette.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -.2)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(
                color: _DashboardPalette.muted, fontSize: 13)),
      ],
    );
  }
}
