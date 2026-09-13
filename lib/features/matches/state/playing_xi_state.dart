class PlayingXiState {
  const PlayingXiState({
    this.teamAPlayerIds = const [],
    this.teamBPlayerIds = const [],
    this.teamABattingOrder = const [],
    this.teamBBattingOrder = const [],
  });

  final List<int> teamAPlayerIds;
  final List<int> teamBPlayerIds;
  final List<int> teamABattingOrder;
  final List<int> teamBBattingOrder;

  PlayingXiState copyWith({
    List<int>? teamAPlayerIds,
    List<int>? teamBPlayerIds,
    List<int>? teamABattingOrder,
    List<int>? teamBBattingOrder,
  }) {
    return PlayingXiState(
      teamAPlayerIds: teamAPlayerIds ?? this.teamAPlayerIds,
      teamBPlayerIds: teamBPlayerIds ?? this.teamBPlayerIds,
      teamABattingOrder: teamABattingOrder ?? this.teamABattingOrder,
      teamBBattingOrder: teamBBattingOrder ?? this.teamBBattingOrder,
    );
  }
}
