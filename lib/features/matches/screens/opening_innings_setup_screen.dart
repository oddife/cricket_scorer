import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/matches/initialize_innings_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/matches/enums/match_team_slot.dart';
import '../../../domain/matches/models/match_player.dart';
import '../providers/match_provider.dart';

class OpeningInningsSetupScreen extends ConsumerStatefulWidget {
  const OpeningInningsSetupScreen({
    super.key,
    required this.matchId,
  });

  final int matchId;

  @override
  ConsumerState<OpeningInningsSetupScreen> createState() =>
      _OpeningInningsSetupScreenState();
}

class _OpeningInningsSetupScreenState
    extends ConsumerState<OpeningInningsSetupScreen> {
  int? _selectedBowlerId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchByIdProvider(widget.matchId));
    final teamsAsync = ref.watch(matchTeamsProvider(widget.matchId));
    final playersAsync = ref.watch(matchPlayersProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Opening Innings')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load match: $error')),
        data: (match) {
          if (match == null) return const Center(child: Text('Match not found.'));
          return teamsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Unable to load teams: $error')),
            data: (teams) => playersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Unable to load players: $error')),
              data: (players) => _buildContent(
                context,
                match: match,
                teams: teams,
                players: players,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required dynamic match,
    required List teams,
    required List<MatchPlayer> players,
  }) {
    final teamA = teams.cast().firstWhere(
      (team) => team.slot == MatchTeamSlot.teamA,
      orElse: () => null,
    );
    final teamB = teams.cast().firstWhere(
      (team) => team.slot == MatchTeamSlot.teamB,
      orElse: () => null,
    );

    if (teamA == null || teamB == null) {
      return const Center(child: Text('Both match teams are required.'));
    }

    final firstBattingTeamId = _firstBattingTeamId(match, teamA.teamId, teamB.teamId);
    final battingTeamId = firstBattingTeamId;
    final bowlingTeamId = battingTeamId == teamA.teamId ? teamB.teamId : teamA.teamId;

    final battingPlayers = players
        .where((player) => player.teamId == battingTeamId && player.isPlaying)
        .toList()
      ..sort((a, b) => (a.battingOrder ?? 9999).compareTo(b.battingOrder ?? 9999));
    final bowlingPlayers = players
        .where((player) => player.teamId == bowlingTeamId && player.isPlaying)
        .toList();

    final selectedBowler = _selectedBowlerId != null &&
            bowlingPlayers.any((player) => player.playerId == _selectedBowlerId)
        ? _selectedBowlerId
        : null;

    final valid = battingPlayers.length >= 2 && bowlingPlayers.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Innings 1',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${match.name}  •  ${match.oversPerInnings} overs  •  ${match.ballsPerOver} balls/over',
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Batting', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(_teamName(teamA, teamB, battingTeamId)),
                      const SizedBox(height: 16),
                      _PlayerRow(
                        label: 'Striker',
                        player: battingPlayers.isNotEmpty ? battingPlayers[0] : null,
                      ),
                      const SizedBox(height: 8),
                      _PlayerRow(
                        label: 'Non-striker',
                        player: battingPlayers.length > 1 ? battingPlayers[1] : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Bowling', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(_teamName(teamA, teamB, bowlingTeamId)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedBowler,
                        decoration: const InputDecoration(
                          labelText: 'First bowler',
                          border: OutlineInputBorder(),
                        ),
                        items: bowlingPlayers
                            .map(
                              (player) => DropdownMenuItem<int>(
                                value: player.playerId,
                                child: Text('Player ${player.playerId}'),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _selectedBowlerId = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: !valid || selectedBowler == null || _saving
                    ? null
                    : () => _startInnings(
                          context,
                          match: match,
                          teamA: teamA,
                          teamB: teamB,
                          players: players,
                          bowlerId: selectedBowler,
                        ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Start Innings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _firstBattingTeamId(dynamic match, int teamAId, int teamBId) {
    final tossWinner = match.tossWinnerTeamId as int?;
    if (match.tossDecision.toString().endsWith('bat')) return tossWinner!;
    return tossWinner == teamAId ? teamBId : teamAId;
  }

  String _teamName(dynamic teamA, dynamic teamB, int teamId) {
    return teamId == teamA.teamId ? teamA.name as String : teamB.name as String;
  }

  Future<void> _startInnings(
    BuildContext context, {
    required dynamic match,
    required dynamic teamA,
    required dynamic teamB,
    required List<MatchPlayer> players,
    required int? bowlerId,
  }) async {
    if (bowlerId == null) return;
    setState(() => _saving = true);

    try {
      final innings = const InitializeInningsService().prepare(
        match: match,
        matchTeams: [teamA, teamB],
        matchPlayers: players,
        inningsNumber: 1,
        firstBowlerId: bowlerId,
      );
      await ref.read(inningsRepositoryProvider).create(innings);
      ref.invalidate(inningsByMatchProvider(widget.matchId));
      if (!context.mounted) return;
      context.go('/matches/${widget.matchId}/live');
    } on ArgumentError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Invalid innings setup.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to start innings: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.label, required this.player});

  final String label;
  final MatchPlayer? player;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(player == null ? 'Not available' : 'Player ${player!.playerId}'),
    );
  }
}
