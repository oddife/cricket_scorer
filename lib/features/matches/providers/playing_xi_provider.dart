import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playing_xi_state.dart';

final playingXiProvider =
    NotifierProvider<PlayingXiNotifier, PlayingXiState>(PlayingXiNotifier.new);

class PlayingXiNotifier extends Notifier<PlayingXiState> {
  @override
  PlayingXiState build() => const PlayingXiState();

  void setTeamAPlayers(List<int> ids) {
    final teamBIds = state.teamBPlayerIds.toSet();
    final filtered = _unique(ids.where((id) => !teamBIds.contains(id)));
    state = state.copyWith(
      teamAPlayerIds: filtered,
      teamABattingOrder: _syncOrder(state.teamABattingOrder, filtered),
    );
  }

  void setTeamBPlayers(List<int> ids) {
    final teamAIds = state.teamAPlayerIds.toSet();
    final filtered = _unique(ids.where((id) => !teamAIds.contains(id)));
    state = state.copyWith(
      teamBPlayerIds: filtered,
      teamBBattingOrder: _syncOrder(state.teamBBattingOrder, filtered),
    );
  }

  void setTeamABattingOrder(List<int> ids) {
    state = state.copyWith(
      teamABattingOrder: _syncOrder(ids, state.teamAPlayerIds),
    );
  }

  void setTeamBBattingOrder(List<int> ids) {
    state = state.copyWith(
      teamBBattingOrder: _syncOrder(ids, state.teamBPlayerIds),
    );
  }

  List<int> _unique(Iterable<int> ids) {
    final seen = <int>{};
    return [for (final id in ids) if (seen.add(id)) id];
  }

  List<int> _syncOrder(Iterable<int> requestedOrder, Iterable<int> selectedIds) {
    final selected = selectedIds.toList();
    final selectedSet = selected.toSet();
    final result = <int>[];
    final added = <int>{};

    for (final id in requestedOrder) {
      if (selectedSet.contains(id) && added.add(id)) {
        result.add(id);
      }
    }

    for (final id in selected) {
      if (added.add(id)) result.add(id);
    }

    return result;
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
      return 'A player cannot appear twice in the Playing XI.';
    }
    if (state.teamAPlayerIds.toSet().intersection(state.teamBPlayerIds.toSet()).isNotEmpty) {
      return 'A player cannot be selected for both teams.';
    }

    // Batting order is normalized from the selected players when the match
    // starts. This prevents stale order entries from blocking a valid XI.
    return null;
  }
}
