import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/matches/enums/match_status.dart';
import '../../matches/providers/match_provider.dart';
import '../../matches/providers/match_setup_provider.dart';
import '../providers/tournament_provider.dart';
import '../providers/tournament_team_provider.dart';
import '../widgets/tournament_logo.dart';

class TournamentProfileScreen extends ConsumerWidget {
  const TournamentProfileScreen({required this.tournamentId, super.key});

  final int tournamentId;

  void _createMatch(BuildContext context, WidgetRef ref, List<dynamic> teams) {
    if (teams.length < 2) return;
    ref.read(matchSetupProvider.notifier).configureTournament(
          tournamentId: tournamentId,
          teamAId: teams[0].id as int,
          teamBId: teams[1].id as int,
        );
    context.push('/matches/normal/new');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentProvider);
    final teamsAsync = ref.watch(tournamentTeamsProvider(tournamentId));
    final matchesAsync = ref.watch(matchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament')),
      floatingActionButton: teamsAsync.maybeWhen(
        data: (teams) => FloatingActionButton.extended(
          onPressed: teams.length < 2 ? null : () => _createMatch(context, ref, teams),
          icon: const Icon(Icons.add),
          label: const Text('Create Match'),
        ),
        orElse: () => null,
      ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load tournament: $error')),
        data: (tournaments) {
          final tournament = tournaments.where((item) => item.id == tournamentId).firstOrNull;
          if (tournament == null) return const Center(child: Text('Tournament not found'));

          final matches = matchesAsync.whenOrNull(
                data: (items) => items
                    .where((match) => match.tournamentId == tournamentId)
                    .toList(),
              ) ??
              const [];
          final teams = teamsAsync.whenOrNull(data: (items) => items) ?? const [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            children: [
              Center(child: TournamentLogo(tournamentName: tournament.name, logoPath: tournament.logoPath, radius: 56)),
              const SizedBox(height: 12),
              Center(child: Text(tournament.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center)),
              const SizedBox(height: 6),
              Center(child: Text(_typeLabel(tournament.type))),
              if (tournament.startDate != null || tournament.endDate != null) ...[
                const SizedBox(height: 8),
                Center(child: Text(_dateRange(tournament.startDate, tournament.endDate))),
              ],
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Teams',
                action: TextButton.icon(
                  onPressed: () => context.push('/tournaments/$tournamentId/manage'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Manage'),
                ),
              ),
              teamsAsync.when(
                loading: () => const Card(child: ListTile(title: LinearProgressIndicator())),
                error: (error, _) => Card(child: ListTile(title: Text('Unable to load teams: $error'))),
                data: (teams) => teams.isEmpty
                    ? const Card(child: ListTile(leading: Icon(Icons.groups_outlined), title: Text('No teams yet'), subtitle: Text('Add at least two teams before creating a tournament match.')))
                    : Card(child: Column(children: [for (var i = 0; i < teams.length; i++) ...[if (i > 0) const Divider(height: 1), ListTile(leading: const Icon(Icons.shield_outlined), title: Text(teams[i].name), subtitle: Text(teams[i].shortName))]])),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Matches',
                action: TextButton.icon(
                  onPressed: teams.length < 2 ? null : () => _createMatch(context, ref, teams),
                  icon: const Icon(Icons.add),
                  label: const Text('New Match'),
                ),
              ),
              matchesAsync.when(
                loading: () => const Card(child: ListTile(title: LinearProgressIndicator())),
                error: (error, _) => Card(child: ListTile(title: Text('Unable to load matches: $error'))),
                data: (_) => matches.isEmpty
                    ? const Card(child: ListTile(leading: Icon(Icons.sports_cricket_outlined), title: Text('No matches yet'), subtitle: Text('Create the first match for this tournament.')))
                    : Card(child: Column(children: [for (var i = 0; i < matches.length; i++) ...[if (i > 0) const Divider(height: 1), ListTile(leading: _statusIcon(matches[i].status), title: Text(matches[i].name), subtitle: Text('${_formatDate(matches[i].date)} • ${matches[i].inningsCount} innings • ${matches[i].oversPerInnings} overs'), trailing: Chip(label: Text(matches[i].status.label)), onTap: () => _openMatch(context, matches[i].id, matches[i].status))]])),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Standings'),
              const Card(child: ListTile(leading: Icon(Icons.leaderboard_outlined), title: Text('Standings will be derived from completed tournament matches.'))),
            ],
          );
        },
      ),
    );
  }

  static void _openMatch(BuildContext context, int matchId, MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
      case MatchStatus.setup:
        context.push('/matches/$matchId/live');
      case MatchStatus.completed:
      case MatchStatus.abandoned:
        context.push('/matches/$matchId/scorecard');
    }
  }

  static Icon _statusIcon(MatchStatus status) => Icon(switch (status) {
        MatchStatus.live => Icons.play_circle_outline,
        MatchStatus.completed => Icons.check_circle_outline,
        MatchStatus.abandoned => Icons.cancel_outlined,
        MatchStatus.setup => Icons.settings_outlined,
      });

  static String _typeLabel(dynamic type) {
    switch (type.toString().split('.').last) {
      case 'league': return 'League';
      case 'knockout': return 'Knockout';
      case 'leagueAndKnockout': return 'League + Knockout';
      default: return type.toString();
    }
  }

  static String _dateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) return '${_formatDate(start)} – ${_formatDate(end)}';
    if (start != null) return 'Starts ${_formatDate(start)}';
    return 'Ends ${_formatDate(end!)}';
  }

  static String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), if (action != null) action!]);
}
