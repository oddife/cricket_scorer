import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/management/permanent_delete_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/matches/enums/match_status.dart';
import '../../tournaments/providers/tournament_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/match_pdf_export_actions.dart';

class RecentMatchesScreen extends ConsumerWidget {
  const RecentMatchesScreen({super.key});

  Future<void> _clearTestMatches(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local match data?'),
        content: const Text(
          'This deletes all local matches, innings and ball events. '
          'Global players, teams, team memberships and tournaments are kept. '
          'Supabase data is not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Match Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(appDatabaseProvider).clearLocalMatchData();
    ref.invalidate(matchProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local match test data cleared.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteMatch(
    BuildContext context,
    WidgetRef ref,
    dynamic match,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete match permanently?'),
        content: Text(
          'Permanently delete “${match.name}” and all of its innings, '
          'deliveries and match data?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(permanentDeleteServiceProvider).deleteMatch(match.id);
      ref.invalidate(matchProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match permanently deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete match: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchProvider);
    final tournaments = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Matches'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Clear local test matches',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _clearTestMatches(context, ref),
            ),
        ],
      ),
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
                  leading: Icon(
                    completed
                        ? Icons.check_circle_outline
                        : Icons.sports_cricket_outlined,
                  ),
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
                        onPressed: () => context.push(
                          '/matches/${match.id}/scorecard',
                        ),
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
                      IconButton(
                        tooltip: 'Delete permanently',
                        onPressed: () => _deleteMatch(context, ref, match),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
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

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
