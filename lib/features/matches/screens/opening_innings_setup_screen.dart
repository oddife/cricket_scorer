import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/matches/initialize_innings_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../domain/matches/enums/match_team_slot.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/matches/models/match_player.dart';
import '../../../domain/matches/models/match_team.dart';
import '../../players/providers/player_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/innings_provider.dart';
import '../providers/live_scoring_provider.dart';
import '../providers/match_provider.dart';

class OpeningInningsSetupScreen extends ConsumerStatefulWidget {
  const OpeningInningsSetupScreen({super.key, required this.matchId});
  final int matchId;

  @override
  ConsumerState<OpeningInningsSetupScreen> createState() =>
      _OpeningInningsSetupScreenState();
}

class _OpeningInningsSetupScreenState
    extends ConsumerState<OpeningInningsSetupScreen> {
  int? _strikerId;
  int? _nonStrikerId;
  int? _firstBowlerId;
  int? _secondBowlerId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchByIdProvider(widget.matchId));
    final teamsAsync = ref.watch(matchTeamsProvider(widget.matchId));
    final playersAsync = ref.watch(matchPlayersProvider(widget.matchId));
    final globalPlayersAsync = ref.watch(playerProvider);
    final globalTeamsAsync = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Opening Innings Setup')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load match: $error')),
        data: (match) {
          if (match == null) return const Center(child: Text('Match not found.'));
          return teamsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Unable to load match teams: $error')),
            data: (teams) => playersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Unable to load match players: $error')),
              data: (players) => globalPlayersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Unable to load player names: $error')),
                data: (globalPlayers) => globalTeamsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Unable to load team names: $error')),
                  data: (globalTeams) => _buildContent(
                    context,
                    match: match,
                    teams: teams,
                    players: players,
                    playerNames: {
                      for (final player in globalPlayers)
                        player.id: player.displayName,
                    },
                    teamNames: {for (final team in globalTeams) team.id: team.name},
                  ),
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
    required Map<int, String> teamNames,
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
    if (match.tossWinnerTeamId == null || match.tossDecision == null) {
      return const Center(child: Text('Toss information is required.'));
    }

    final firstBattingTeamId = _firstBattingTeamId(
      match,
      teamA.teamId,
      teamB.teamId,
    );
    final bowlingTeamId =
        firstBattingTeamId == teamA.teamId ? teamB.teamId : teamA.teamId;

    final battingPlayers = players
        .where((player) =>
            player.teamId == firstBattingTeamId && player.isPlaying)
        .toList();
    final bowlingPlayers = players
        .where((player) => player.teamId == bowlingTeamId && player.isPlaying)
        .toList();

    final striker = _validSelection(_strikerId, battingPlayers);
    final nonStriker = _validSelection(_nonStrikerId, battingPlayers);
    final firstBowler = _validSelection(_firstBowlerId, bowlingPlayers);
    final secondBowler = _validSelection(_secondBowlerId, bowlingPlayers);

    final openingBowlingValid = match.twoBowlerMode
        ? bowlingPlayers.length >= 2 &&
            firstBowler != null &&
            secondBowler != null &&
            firstBowler != secondBowler
        : firstBowler != null;
    final valid = battingPlayers.length >= 2 &&
        bowlingPlayers.isNotEmpty &&
        striker != null &&
        nonStriker != null &&
        striker != nonStriker &&
        openingBowlingValid;

    String playerName(int id) => playerNames[id] ?? 'Player $id';
    String teamName(int id) => teamNames[id] ?? 'Team $id';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Opening Innings',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('${match.name} • ${match.oversPerInnings} overs • ${match.ballsPerOver} balls/over'),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Opening batsmen',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(teamName(firstBattingTeamId)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: striker,
                        decoration: const InputDecoration(
                          labelText: 'Striker',
                          border: OutlineInputBorder(),
                        ),
                        items: battingPlayers
                            .map((player) => DropdownMenuItem<int>(
                                  value: player.playerId,
                                  child: Text(playerName(player.playerId)),
                                ))
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _strikerId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: nonStriker,
                        decoration: const InputDecoration(
                          labelText: 'Non-striker',
                          border: OutlineInputBorder(),
                        ),
                        items: battingPlayers
                            .map((player) => DropdownMenuItem<int>(
                                  value: player.playerId,
                                  child: Text(playerName(player.playerId)),
                                ))
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _nonStrikerId = value),
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
                        match.twoBowlerMode ? 'Opening bowlers' : 'Opening bowler',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(teamName(bowlingTeamId)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: firstBowler,
                        decoration: InputDecoration(
                          labelText: match.twoBowlerMode
                              ? 'Opening bowler 1'
                              : 'Opening bowler',
                          border: const OutlineInputBorder(),
                        ),
                        items: bowlingPlayers
                            .map((player) => DropdownMenuItem<int>(
                                  value: player.playerId,
                                  child: Text(playerName(player.playerId)),
                                ))
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _firstBowlerId = value),
                      ),
                      if (match.twoBowlerMode) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: secondBowler,
                          decoration: const InputDecoration(
                            labelText: 'Opening bowler 2',
                            border: OutlineInputBorder(),
                          ),
                          items: bowlingPlayers
                              .map((player) => DropdownMenuItem<int>(
                                    value: player.playerId,
                                    child: Text(playerName(player.playerId)),
                                  ))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _secondBowlerId = value),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The two opening bowlers alternate on every legal delivery.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: valid && !_saving
                    ? () => _startInnings(
                          context,
                          match: match,
                          teams: [teamA!, teamB!],
                          players: players,
                          strikerId: striker!,
                          nonStrikerId: nonStriker!,
                          bowlerId: firstBowler!,
                          secondBowlerId: secondBowler,
                        )
                    : null,
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

  int? _validSelection(int? id, List<MatchPlayer> players) {
    if (id == null) return null;
    return players.any((player) => player.playerId == id) ? id : null;
  }

  int _firstBattingTeamId(Match match, int teamAId, int teamBId) {
    final tossWinnerId = match.tossWinnerTeamId!;
    return match.tossDecision!.name == 'bat'
        ? tossWinnerId
        : (tossWinnerId == teamAId ? teamBId : teamAId);
  }

  Future<void> _startInnings(
    BuildContext context, {
    required Match match,
    required List<MatchTeam> teams,
    required List<MatchPlayer> players,
    required int strikerId,
    required int nonStrikerId,
    required int bowlerId,
    required int? secondBowlerId,
  }) async {
    setState(() => _saving = true);
    try {
      final innings = const InitializeInningsService().prepare(
        match: match,
        matchTeams: teams,
        matchPlayers: players,
        inningsNumber: 1,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        firstBowlerId: bowlerId,
      );
      final created = await ref.read(inningsRepositoryProvider).create(innings);
      ref.invalidate(inningsByMatchProvider(widget.matchId));

      if (match.twoBowlerMode && secondBowlerId != null) {
        await ref.read(liveScoringProvider(created.id).future);
        ref.read(liveScoringProvider(created.id).notifier)
            .selectTwoBowlerPair([bowlerId, secondBowlerId]);
      }

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
