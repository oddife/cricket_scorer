import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Scorer'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cricket Scorer', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Create a tournament or start a normal match', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          _ActionCard(
                            icon: Icons.emoji_events_outlined,
                            title: 'Tournament',
                            subtitle: 'Create or manage tournaments',
                            onTap: () {},
                          ),
                          const SizedBox(height: 16),
                          _ActionCard(
                            icon: Icons.sports_cricket,
                            title: 'Normal Match',
                            subtitle: 'Start a standalone match',
                            onTap: () {},
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.emoji_events_outlined,
                            title: 'Tournament',
                            subtitle: 'Create or manage tournaments',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.sports_cricket,
                            title: 'Normal Match',
                            subtitle: 'Start a standalone match',
                            onTap: () {},
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                _Section(title: 'Live Matches', child: const _EmptyState(icon: Icons.live_tv_outlined, message: 'No live matches')),
                const SizedBox(height: 32),
                _Section(title: 'Recent Matches', child: const _EmptyState(icon: Icons.history, message: 'No recent matches')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
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
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
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
}
