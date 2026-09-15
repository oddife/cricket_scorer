import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tournament_provider.dart';
import '../widgets/tournament_logo.dart';

class TournamentProfileScreen extends ConsumerWidget {
  const TournamentProfileScreen({required this.tournamentId, super.key});

  final int tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Profile')),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load tournament: $error')),
        data: (tournaments) {
          final tournament = tournaments.where((item) => item.id == tournamentId).firstOrNull;
          if (tournament == null) {
            return const Center(child: Text('Tournament not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: TournamentLogo(
                  tournamentName: tournament.name,
                  logoPath: tournament.logoPath,
                  radius: 64,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  tournament.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Tournament type'),
                  trailing: Text(_typeLabel(tournament.type)),
                ),
              ),
              if (tournament.startDate != null) Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Start date'),
                  trailing: Text(_formatDate(tournament.startDate!)),
                ),
              ),
              if (tournament.endDate != null) Card(
                child: ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('End date'),
                  trailing: Text(_formatDate(tournament.endDate!)),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.sports_cricket_outlined),
                  title: Text('Matches'),
                  subtitle: Text('Tournament matches will appear here.'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.leaderboard_outlined),
                  title: Text('Standings'),
                  subtitle: Text('Points and standings will be derived from tournament matches.'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _typeLabel(dynamic type) {
    switch (type.toString().split('.').last) {
      case 'league': return 'League';
      case 'knockout': return 'Knockout';
      case 'leagueAndKnockout': return 'League + Knockout';
      default: return type.toString();
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
