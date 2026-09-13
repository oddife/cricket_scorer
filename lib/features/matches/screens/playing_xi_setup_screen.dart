import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/matches/start_match_service.dart';
import '../../../../core/database/database_provider.dart';
import '../../teams/providers/team_player_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/playing_xi_provider.dart';
import '../providers/match_setup_provider.dart';
import '../widgets/setup/playing_xi_editor.dart';

class PlayingXiSetupScreen extends ConsumerWidget {
  const PlayingXiSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(matchSetupProvider);
    final teamsAsync = ref.watch(teamProvider);

    if (setup.teamAId == null || setup.teamBId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playing XI')),
        body: const Center(
          child: Text('Select both teams before setting the Playing XI.'),
        ),
      );
    }

    final teams = teamsAsync.value ?? const [];
    final teamA = teams.where((team) => team.id == setup.teamAId).firstOrNull;
    final teamB = teams.where((team) => team.id == setup.teamBId).firstOrNull;

    if (teamA == null || teamB == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playing XI')),
        body: teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Unable to load teams: $error')),
          data: (_) => const Center(
            child: Text('The selected teams could not be found.'),
          ),
        ),
      );
    }

    final teamAPlayers = ref.watch(teamPlayersProvider(teamA.id));
    final teamBPlayers = ref.watch(teamPlayersProvider(teamB.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Playing XI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: teamAPlayers.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) =>
                  Text('Unable to load ${teamA.name} squad: $error'),
              data: (aPlayers) => teamBPlayers.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    Text('Unable to load ${teamB.name} squad: $error'),
                data: (bPlayers) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Playing XI',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select ${setup.playersPerTeam} players for each team and set the batting order.',
                    ),
                    const SizedBox(height: 20),
                    PlayingXiEditor(
                      teamAName: teamA.name,
                      teamBName: teamB.name,
                      teamAId: teamA.id,
                      teamBId: teamB.id,
                      teamAPlayers: aPlayers,
                      teamBPlayers: bPlayers,
                      playersPerTeam: setup.playersPerTeam,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _startMatch(context, ref),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Match'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startMatch(BuildContext context, WidgetRef ref) async {
    final setup = ref.read(matchSetupProvider);
    final xi = ref.read(playingXiProvider);
    final error = ref.read(playingXiProvider.notifier).validate(
          playersPerTeam: setup.playersPerTeam,
        );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    try {
      final match = await StartMatchService(
        ref.read(matchRepositoryProvider),
      ).start(setup: setup, playingXi: xi);
      if (!context.mounted) return;
      context.go('/matches/${match.id}/opening');
    } on ArgumentError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message?.toString() ?? 'Invalid match setup.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to start match: $error')),
      );
    }
  }
}
