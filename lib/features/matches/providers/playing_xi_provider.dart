import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playing_xi_state.dart';

final playingXiProvider =
    NotifierProvider<PlayingXiNotifier, PlayingXiState>(PlayingXiNotifier.new);

class PlayingXiNotifier extends Notifier<PlayingXiState> {
  @override
  PlayingXiState build() => const PlayingXiState();

  void setTeamAPlayers(List<int> ids) {
    final teamBIds = state.teamBPlayerIds.toSet();
    final filtered = ids.where((id) => !teamBIds.contains(id)).toList();
    state = state.copyWith(
      teamAPlayerIds: List.unmodifiable(filtered),
      teamABattingOrder: List.unmodifiable(filtered),
    );
  }

  void setTeamBPlayers(List<int> ids) {
    final teamAIds = state.teamAPlayerIds.toSet();
    final filtered = ids.where((id) => !teamAIds.contains(id)).toList();
    state = state.copyWith(
      teamBPlayerIds: List.unmodifiable(filtered),
      teamBBattingOrder: List.unmodifiable(filtered),
    );
  }

  void setTeamABattingOrder(List<int> ids) {
    state = state.copyWith(teamABattingOrder: List.unmodifiable(ids));
  }

  void setTeamBBattingOrder(List<int> ids) {
    state = state.copyWith(teamBBattingOrder: List.unmodifiable(ids));
  }

  String? validate({required int playersPerTeam}) {
    if (state.teamAPlayerIds.length != playersPerTeam) {
      return 'Select exactly $playersPerTeam players for Team A.';
    }
    if (state.teamBPlayerIds.length != playersPerTeam) {
      return 'Select exactly $playersPerTeam players for Team B.';
    }
    if (state.teamAPlayerIds.toSet().length != state.teamAPlayerIds.length ||
        state.teamBPlayerIds.toSet().length != state.teamBPlayerIds.length) {
      return 'A player cannot appear twice in the same Playing XI.';
    }
    if (state.teamAPlayerIds.toSet().intersection(state.teamBPlayerIds.toSet()).isNotEmpty) {
      return 'A player cannot be selected for both teams.';
    }
    if (state.teamABattingOrder.length != playersPerTeam ||
        state.teamBBattingOrder.length != playersPerTeam) {
      return 'Set the complete batting order for both teams.';
    }
    if (state.teamABattingOrder.toSet() != state.teamAPlayerIds.toSet() ||
        state.teamBBattingOrder.toSet() != state.teamBPlayerIds.toSet()) {
      return 'Batting order must contain every selected player exactly once.';
    }
    return null;
  }
}
