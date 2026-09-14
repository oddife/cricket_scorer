import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playing_xi_state.dart';

final playingXiProvider =
    NotifierProvider<PlayingXiNotifier, PlayingXiState>(PlayingXiNotifier.new);

class PlayingXiNotifier extends Notifier<PlayingXiState> {
  @override
  PlayingXiState build() => const PlayingXiState();

  void setTeamAPlayers(List<int> ids) {
    final teamBIds = state.teamBPlayerIds.toSet();
    state = state.copyWith(
      teamAPlayerIds: _unique(ids.where((id) => !teamBIds.contains(id))),
    );
  }

  void setTeamBPlayers(List<int> ids) {
    final teamAIds = state.teamAPlayerIds.toSet();
    state = state.copyWith(
      teamBPlayerIds: _unique(ids.where((id) => !teamAIds.contains(id))),
    );
  }

  // Kept for compatibility with existing setup state. Batting order is now
  // chosen during opening innings setup, not during player selection.
  void setTeamABattingOrder(List<int> ids) {
    state = state.copyWith(teamABattingOrder: _unique(ids));
  }

  void setTeamBBattingOrder(List<int> ids) {
    state = state.copyWith(teamBBattingOrder: _unique(ids));
  }

  List<int> _unique(Iterable<int> ids) {
    final seen = <int>{};
    return [for (final id in ids) if (seen.add(id)) id];
  }

  String? validate({required int playersPerTeam}) {
    final teamA = state.teamAPlayerIds.toSet();
    final teamB = state.teamBPlayerIds.toSet();

    if (teamA.length != state.teamAPlayerIds.length ||
        teamB.length != state.teamBPlayerIds.length) {
      return 'A player cannot appear twice in the match player list.';
    }
    if (teamA.intersection(teamB).isNotEmpty) {
      return 'A player cannot be selected for both teams.';
    }
    if (teamA.length > playersPerTeam || teamB.length > playersPerTeam) {
      return 'Selected players cannot exceed the configured players per team.';
    }
    if (teamA.length < 2 || teamB.length < 2) {
      return 'At least two available players are required for each team.';
    }
    return null;
  }
}
