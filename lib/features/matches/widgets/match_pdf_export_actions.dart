import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../application/export/match_full_pdf_export_service.dart';
import '../../../application/export/match_pdf_export_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/innings/services/innings_recalculation_engine.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/matches/services/match_result_service.dart';
import '../../players/providers/player_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/innings_provider.dart';
import '../providers/match_provider.dart';

class MatchPdfExportActions extends ConsumerStatefulWidget {
  const MatchPdfExportActions({super.key, required this.match});
  final Match match;

  @override
  ConsumerState<MatchPdfExportActions> createState() => _MatchPdfExportActionsState();
}

class _MatchPdfExportActionsState extends ConsumerState<MatchPdfExportActions> {
  bool _exporting = false;

  Future<void> _export({required bool full}) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final innings = await ref.read(inningsByMatchProvider(widget.match.id).future);
      final matchTeams = await ref.read(matchTeamsProvider(widget.match.id).future);
      final matchPlayers = await ref.read(matchPlayersProvider(widget.match.id).future);
      final teams = await ref.read(teamProvider.future);
      final players = await ref.read(playerProvider.future);
      final tournament = widget.match.tournamentId == null
          ? null
          : (await ref.read(tournamentRepositoryProvider).getAll())
              .where((item) => item.id == widget.match.tournamentId)
              .firstOrNull;
      final repository = ref.read(ballEventRepositoryProvider);
      final bytes = full
          ? await MatchFullPdfExportService(
              ballEventRepository: repository,
              recalculationEngine: const InningsRecalculationEngine(),
              matchResultService: const MatchResultService(),
            ).generate(
              match: widget.match,
              innings: innings,
              matchTeams: matchTeams,
              matchPlayers: matchPlayers,
              teams: teams,
              players: players,
              tournament: tournament,
            )
          : await const MatchPdfExportService().build(
              match: widget.match,
              innings: innings,
              matchTeams: matchTeams,
              matchPlayers: matchPlayers,
              teams: teams,
              players: players,
              tournament: tournament,
              ballRepository: repository,
            );
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_safeFileName(widget.match.name)}_${full ? 'full' : 'short'}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to export PDF: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _safeFileName(String value) => value.trim().isEmpty
      ? 'match-scorecard'
      : value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export(full: false),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Short Scorecard PDF'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export(full: true),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Full Scorecard PDF'),
          ),
          if (_exporting) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      );
}
