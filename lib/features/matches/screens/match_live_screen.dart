import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/matches/enums/match_team_slot.dart';
import '../providers/match_provider.dart';

class MatchLiveScreen extends ConsumerWidget {
  const MatchLiveScreen({super.key, required this.matchId});

  final int matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchByIdProvider(matchId));
    final teamsAsync = ref.watch(matchTeamsProvider(matchId));
    final playersAsync = ref.watch(matchPlayersProvider(matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Live Match')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load match: $error')),
        data: (match) {
          if (match == null) return const Center(child: Text('Match not found.'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(match.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('${match.inningsCount} innings  •  ${match.oversPerInnings} overs  •  ${match.ballsPerOver} balls/over'),
                    const SizedBox(height: 4),
                    Text(match.twoBowlerMode ? '2-Bowler Mode enabled' : 'Standard bowling mode'),
                    const SizedBox(height: 20),
                    teamsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => Text('Unable to load match teams: $error'),
                      data: (teams) => Column(
                        children: [
                          for (final team in teams)
                            ListTile(
                              leading: Icon(team.slot == MatchTeamSlot.teamA ? Icons.looks_one : Icons.looks_two),
                              title: Text(team.slot.label),
                              subtitle: Text('Team ID ${team.teamId}'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    playersAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => Text('Unable to load match players: $error'),
                      data: (players) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('${players.where((p) => p.isPlaying).length} Playing XI players persisted'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.sports_cricket, size: 48),
                            SizedBox(height: 12),
                            Text('Match started successfully.'),
                            SizedBox(height: 4),
                            Text('Live scoring screen will be added in the scoring engine phase.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
