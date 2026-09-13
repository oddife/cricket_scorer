import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/matches/initialize_innings_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/matches/enums/match_team_slot.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/matches/models/match_player.dart';
import '../../../domain/teams/models/team.dart';
import '../../players/providers/player_provider.dart';
import '../providers/innings_provider.dart';
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
    final globalPlayersAsync = ref.watch(playerProvider);

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
              error: (error, _) => Center(child: Text('Unable to load match players: $error')),
              data: (players) => globalPlayersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Unable to load player names: $error')),
                data: (globalPlayers) => _buildContent(
                  context,
                  match: match,
                  teams: teams,
                  players: players,
                  playerNames: {
                    for (final player in globalPlayers) player.id: player.displayName,
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Match match,
    required List<MatchTeam> teams,
    required List<MatchPlayer> players,
    required Map<int, String> playerNames,
  }) {
    MatchTeam? teamA;
    MatchTeam? teamB;
    for (final team in teams) {
      if (team.slot == MatchTeamSlot.teamA) teamA = team;
      if (team.slot == MatchTeamSlot.teamB) teamB = team;
    }

    if (teamA == null || teamB == null) {
      return const Center(child: Text('Both match teams are required.'));
    }

    final firstBattingTeamId = _firstBattingTeamId(
      match,
      teamA!.teamId,
      teamB!.teamId,
    );
    final battingTeamId = firstBattingTeamId;
    final bowlingTeamId =
        battingTeamId == teamA!.teamId ? teamB!.teamId : teamA!.teamId;

    final battingPlayers = players
        .where((player) => player.teamId == battingTeamId && player.isPlaying)
        .toList()
      ..sort(
        (a, b) => (a.battingOrder ?? 9999).compareTo(b.battingOrder ?? 9999),
      );
    final bowlingPlayers = players
        .where((player) => player.teamId == bowlingTeamId && player.isPlaying)
        .toList();

    final selectedBowler = _selectedBowlerId != null &&
            bowlingPlayers.any((player) => player.playerId == _selectedBowlerId)
        ? _selectedBowlerId
        : null;

    final valid = battingPlayers.length >= 2 && bowlingPlayers.isNotEmpty;

    String playerName(MatchPlayer player) =>
        playerNames[player.playerId] ?? 'Player ${player.playerId}';

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
                      Text(
                        'Batting',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_teamName(teamA!, teamB!, battingTeamId)),
                      const SizedBox(height: 16),
                      _PlayerRow(
                        label: 'Striker',
                        name: battingPlayers.isNotEmpty
                            ? playerName(battingPlayers[0])
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _PlayerRow(
                        label: 'Non-striker',
                        name: battingPlayers.length > 1
                            ? playerName(battingPlayers[1])
                            : null,
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
                      Text(
                        'Bowling',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_teamName(teamA!, teamB!, bowlingTeamId)),
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
                                child: Text(playerName(player)),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) =>
                                setState(() => _selectedBowlerId = value),
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
                          teams: [teamA!, teamB!],
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

  int _firstBattingTeamId(Match match, int teamAId, int teamBId) {
    final tossWinnerId = match.tossWinnerTeamId!;
    return match.tossDecision!.name == 'bat'
        ? tossWinnerId
        : (tossWinnerId == teamAId ? teamBId : teamAId);
  }

  String _teamName(MatchTeam teamA, MatchTeam teamB, int teamId) {
    return teamId == teamA.teamId ? 'Team A' : 'Team B';
  }

  Future<void> _startInnings(
    BuildContext context, {
    required Match match,
    required List<MatchTeam> teams,
    required List<MatchPlayer> players,
    required int? bowlerId,
  }) async {
    if (bowlerId == null) return;
    setState(() => _saving = true);

    try {
      final innings = const InitializeInningsService().prepare(
        match: match,
        matchTeams: teams,
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
        SnackBar(
          content: Text(
            error.message?.toString() ?? 'Invalid innings setup.',
          ),
        ),
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
  const _PlayerRow({required this.label, required this.name});

  final String label;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(name ?? 'Not available'),
    );
  }
}
