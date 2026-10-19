import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/matches/enums/match_status.dart';
import '../providers/match_provider.dart';

class LiveMatchesScreen extends ConsumerStatefulWidget {
  const LiveMatchesScreen({super.key});

  @override
  ConsumerState<LiveMatchesScreen> createState() => _LiveMatchesScreenState();
}

class _LiveMatchesScreenState extends ConsumerState<LiveMatchesScreen> {
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
        title: const Text('Live Matches'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(matchProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Unable to load live matches: $error'),
        ),
        data: (matches) {
          final liveMatches = matches
              .where((match) => match.status == MatchStatus.live)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (liveMatches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('No live matches'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: liveMatches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final match = liveMatches[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.live_tv_outlined),
                  title: Text(match.name),
                  subtitle: Text(
                    '${_date(match.date)}  •  ${match.oversPerInnings} overs  •  ${match.inningsCount} innings',
                  ),
                  trailing: FilledButton.icon(
                    onPressed: () => context.push('/matches/${match.id}/live'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Open'),
                  ),
                  onTap: () => context.push('/matches/${match.id}/live'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
