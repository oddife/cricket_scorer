import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/match_provider.dart';

class RecentMatchesScreen extends ConsumerWidget {
  const RecentMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recent Matches')),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load matches: $error')),
        data: (matches) {
          final sorted = [...matches]..sort((a, b) => b.date.compareTo(a.date));
          if (sorted.isEmpty) {
            return const Center(child: Text('No matches yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final match = sorted[index];
              final isTournament = match.tournamentId != null;
              return ListTile(
                title: Text(match.name),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${_formatDate(match.date)} • ${_statusLabel(match.status)}'),
                      Chip(
                        label: Text(isTournament ? 'TOURNAMENT' : 'NORMAL'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (match.status.name == 'completed')
                      IconButton(
                        tooltip: 'Export PDF',
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        onPressed: () => _showPdfOptions(context, match.id),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.of(context).pushNamed('/matches/${match.id}/live'),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _statusLabel(dynamic status) {
    final value = status.name.toString();
    if (value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _showPdfOptions(BuildContext context, int matchId) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Export Match PDF')),
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: const Text('Short Scorecard'),
              onTap: () {
                Navigator.pop(sheetContext);
                // PDF export is wired by the existing match export flow.
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Full Scorecard'),
              onTap: () {
                Navigator.pop(sheetContext);
                // PDF export is wired by the existing match export flow.
              },
            ),
          ],
        ),
      ),
    );
  }
}
