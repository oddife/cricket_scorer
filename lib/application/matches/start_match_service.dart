import '../../data/repositories/match_repository.dart';
import '../../domain/matches/enums/match_status.dart';
import '../../domain/matches/enums/match_team_slot.dart';
import '../../domain/matches/models/match.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../features/matches/state/match_setup_state.dart';
import '../../features/matches/state/playing_xi_state.dart';

class StartMatchService {
  StartMatchService(this._repository);

  final MatchRepository _repository;

  Future<Match> start({
    required MatchSetupState setup,
    required PlayingXiState playingXi,
  }) async {
    final validationError = _validate(setup, playingXi);
    if (validationError != null) throw ArgumentError(validationError);

    final match = Match(
      id: 0,
      name: setup.name.trim(),
      date: setup.date!,
      venue: setup.venue.trim().isEmpty ? null : setup.venue.trim(),
      inningsCount: setup.inningsCount,
      oversPerInnings: setup.oversPerInnings,
      ballsPerOver: setup.ballsPerOver,
      playersPerTeam: setup.playersPerTeam,
      twoBowlerMode: setup.twoBowlerMode,
      status: MatchStatus.setup,
    );

    Match? created;
    try {
      created = await _repository.create(match);

      await _repository.setTeam(
        matchId: created.id,
        teamId: setup.teamAId!,
        slot: MatchTeamSlot.teamA,
      );
      await _repository.setTeam(
        matchId: created.id,
        teamId: setup.teamBId!,
        slot: MatchTeamSlot.teamB,
      );

      for (final playerId in playingXi.teamAPlayerIds) {
        await _repository.addPlayer(
          matchId: created.id,
          teamId: setup.teamAId!,
          playerId: playerId,
        );
      }
      for (final playerId in playingXi.teamBPlayerIds) {
        await _repository.addPlayer(
          matchId: created.id,
          teamId: setup.teamBId!,
          playerId: playerId,
        );
      }

      await _repository.setPlayingXi(
        matchId: created.id,
        teamId: setup.teamAId!,
        playerIds: playingXi.teamABattingOrder,
      );
      await _repository.setPlayingXi(
        matchId: created.id,
        teamId: setup.teamBId!,
        playerIds: playingXi.teamBBattingOrder,
      );

      await _repository.setToss(
        matchId: created.id,
        tossWinnerTeamId: setup.tossWinnerTeamId!,
        decision: setup.tossDecision!,
      );

      final liveMatch = created.copyWith(
        tossWinnerTeamId: setup.tossWinnerTeamId,
        tossDecision: setup.tossDecision,
        status: MatchStatus.live,
      );
      await _repository.update(liveMatch);
      return liveMatch;
    } catch (_) {
      if (created != null) {
        try {
          await _repository.delete(created.id);
        } catch (_) {
          // Preserve the original start failure.
        }
      }
      rethrow;
    }
  }

  String? _validate(MatchSetupState setup, PlayingXiState playingXi) {
    if (setup.name.trim().isEmpty) return 'Match name is required.';
    if (setup.date == null) return 'Match date is required.';
    if (setup.inningsCount != 2 && setup.inningsCount != 4) {
      return 'Innings must be 2 or 4.';
    }
    if (setup.oversPerInnings <= 0 || setup.ballsPerOver <= 0) {
      return 'Overs and balls per over must be greater than 0.';
    }
    if (setup.playersPerTeam <= 0) {
      return 'Players per team must be greater than 0.';
    }
    if (setup.teamAId == null || setup.teamBId == null) {
      return 'Both teams are required.';
    }
    if (setup.teamAId == setup.teamBId) {
      return 'Team A and Team B must be different.';
    }
    if (setup.tossWinnerTeamId == null || setup.tossDecision == null) {
      return 'Toss winner and decision are required.';
    }
    if (setup.tossWinnerTeamId != setup.teamAId &&
        setup.tossWinnerTeamId != setup.teamBId) {
      return 'Toss winner must be one of the match teams.';
    }
    if (playingXi.teamAPlayerIds.length != setup.playersPerTeam ||
        playingXi.teamBPlayerIds.length != setup.playersPerTeam) {
      return 'Select exactly ${setup.playersPerTeam} players for each team.';
    }
    if (playingXi.teamAPlayerIds.toSet().intersection(
          playingXi.teamBPlayerIds.toSet(),
        ).isNotEmpty) {
      return 'A player cannot be selected for both teams.';
    }
    if (playingXi.teamABattingOrder.toSet() !=
            playingXi.teamAPlayerIds.toSet() ||
        playingXi.teamBBattingOrder.toSet() !=
            playingXi.teamBPlayerIds.toSet()) {
      return 'Batting order must contain every selected player exactly once.';
    }
    return null;
  }
}
