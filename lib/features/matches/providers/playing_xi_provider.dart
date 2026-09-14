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
      teamABattingOrder: _retainSelectedOrder(
        state.teamABattingOrder,
        filtered,
      ),
    );
  }

  void setTeamBPlayers(List<int> ids) {
    final teamAIds = state.teamAPlayerIds.toSet();
    final filtered = _unique(ids.where((id) => !teamAIds.contains(id)));
    state = state.copyWith(
      teamBPlayerIds: filtered,
      teamBBattingOrder: _retainSelectedOrder(
        state.teamBBattingOrder,
        filtered,
      ),
    );
  }

  void setTeamABattingOrder(List<int> ids) {
    state = state.copyWith(
      teamABattingOrder: _retainSelectedOrder(ids, state.teamAPlayerIds),
    );
  }

  void setTeamBBattingOrder(List<int> ids) {
    state = state.copyWith(
      teamBBattingOrder: _retainSelectedOrder(ids, state.teamBPlayerIds),
    );
  }

  List<int> _unique(Iterable<int> ids) {
    final seen = <int>{};
    return [for (final id in ids) if (seen.add(id)) id];
  }

  /// Selection and batting order are intentionally independent.
  /// Removing a selected player removes them from the existing order, but
  /// selecting a new player never silently adds them to the batting order.
  List<int> _retainSelectedOrder(
    Iterable<int> requestedOrder,
    Iterable<int> selectedIds,
  ) {
    final selected = selectedIds.toSet();
    final added = <int>{};
    return [
      for (final id in requestedOrder)
        if (selected.contains(id) && added.add(id)) id,
    ];
  }

  String? validate({required int playersPerTeam}) {
    if (state.teamAPlayerIds.length < playersPerTeam) {
      return 'Select at least $playersPerTeam players for Team A.';
    }
    if (state.teamBPlayerIds.length < playersPerTeam) {
      return 'Select at least $playersPerTeam players for Team B.';
    }
    if (state.teamAPlayerIds.toSet().length != state.teamAPlayerIds.length ||
        state.teamBPlayerIds.toSet().length != state.teamBPlayerIds.length) {
      return 'A player cannot appear twice in the match player list.';
    }
    if (state.teamAPlayerIds.toSet().intersection(
          state.teamBPlayerIds.toSet(),
        ).isNotEmpty) {
      return 'A player cannot be selected for both teams.';
    }
    if (state.teamABattingOrder.length != playersPerTeam) {
      return 'Select exactly $playersPerTeam players for Team A batting order.';
    }
    if (state.teamBBattingOrder.length != playersPerTeam) {
      return 'Select exactly $playersPerTeam players for Team B batting order.';
    }
    if (!state.teamAPlayerIds.toSet().containsAll(state.teamABattingOrder) ||
        state.teamABattingOrder.toSet().length !=
            state.teamABattingOrder.length) {
      return 'Team A batting order contains an invalid player.';
    }
    if (!state.teamBPlayerIds.toSet().containsAll(state.teamBBattingOrder) ||
        state.teamBBattingOrder.toSet().length !=
            state.teamBBattingOrder.length) {
      return 'Team B batting order contains an invalid player.';
    }
    return null;
  }
}
