import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/matches/enums/match_status.dart';
import '../../tournaments/providers/tournament_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/match_pdf_export_actions.dart';

class RecentMatchesScreen extends ConsumerWidget {
  const RecentMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchProvider);
    final tournaments = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recent Matches')),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load matches: $error')),
        data: (items) {
          final sorted = [...items]..sort((a, b) => b.date.compareTo(a.date));
          if (sorted.isEmpty) return const Center(child: Text('No matches yet.'));

          final tournamentNames = tournaments.maybeWhen(
            data: (items) => {
              for (final tournament in items) tournament.id: tournament.name,
            },
            orElse: () => <int, String>{},
          );

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final match = sorted[index];
              final completed = match.status == MatchStatus.completed;
              final tournamentName = match.tournamentId == null
                  ? null
                  : tournamentNames[match.tournamentId!];
              final matchTag = tournamentName == null
                  ? 'NORMAL'
                  : 'T-$tournamentName';

              return Card(
                child: ListTile(
                  leading: Icon(completed ? Icons.check_circle_outline : Icons.sports_cricket_outlined),
                  title: Text(match.name),
                  subtitle: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${_date(match.date)}  |  ${match.status.label}'),
                      Chip(
                        label: Text(matchTag),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Scorecard',
                        onPressed: () => context.push('/matches/${match.id}/scorecard'),
                        icon: const Icon(Icons.scoreboard_outlined),
                      ),
                      if (completed)
                        IconButton(
                          tooltip: 'Export PDF',
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            builder: (_) => SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: MatchPdfExportActions(match: match),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                        ),
                    ],
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

  static String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
