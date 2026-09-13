import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/matches/enums/toss_decision.dart';
import '../state/match_setup_state.dart';

final matchSetupProvider = NotifierProvider<MatchSetupNotifier, MatchSetupState>(
  MatchSetupNotifier.new,
);

class MatchSetupNotifier extends Notifier<MatchSetupState> {
  @override
  MatchSetupState build() => MatchSetupState(date: DateTime.now());

  void setName(String value) => state = state.copyWith(name: value);
  void setDate(DateTime value) => state = state.copyWith(date: value);
  void setVenue(String value) => state = state.copyWith(venue: value);
  void setInningsCount(int value) => state = state.copyWith(inningsCount: value);
  void setOversPerInnings(int value) =>
      state = state.copyWith(oversPerInnings: value);
  void setBallsPerOver(int value) =>
      state = state.copyWith(ballsPerOver: value);
  void setPlayersPerTeam(int value) =>
      state = state.copyWith(playersPerTeam: value);
  void setTwoBowlerMode(bool value) =>
      state = state.copyWith(twoBowlerMode: value);
  void setTeamA(int teamId) => state = state.copyWith(teamAId: teamId);
  void setTeamB(int teamId) => state = state.copyWith(teamBId: teamId);
  void setTossWinner(int teamId) =>
      state = state.copyWith(tossWinnerTeamId: teamId);
  void setTossDecision(TossDecision value) =>
      state = state.copyWith(tossDecision: value);

  String? validate() {
    if (state.name.trim().isEmpty) return 'Match name is required.';
    if (state.date == null) return 'Match date is required.';
    if (state.inningsCount != 2 && state.inningsCount != 4) {
      return 'Innings must be 2 or 4.';
    }
    if (state.oversPerInnings <= 0) return 'Overs must be greater than 0.';
    if (state.ballsPerOver <= 0) return 'Balls per over must be greater than 0.';
    if (state.playersPerTeam <= 0) {
      return 'Players per team must be greater than 0.';
    }
    if (state.teamAId == null || state.teamBId == null) {
      return 'Both teams are required.';
    }
    if (state.teamAId == state.teamBId) {
      return 'Team A and Team B must be different.';
    }
    if (state.tossWinnerTeamId == null || state.tossDecision == null) {
      return 'Toss winner and decision are required.';
    }
    if (state.tossWinnerTeamId != state.teamAId &&
        state.tossWinnerTeamId != state.teamBId) {
      return 'Toss winner must be one of the match teams.';
    }
    return null;
  }
}
