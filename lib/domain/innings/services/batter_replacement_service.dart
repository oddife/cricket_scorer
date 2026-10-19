class BatterReplacementService {
  const BatterReplacementService();

  List<int> eligibleBatters({
    required List<int> playingBatterIds,
    required Set<int> battedPlayerIds,
    required int strikerId,
    required int nonStrikerId,
  }) {
    if (strikerId <= 0 || nonStrikerId <= 0 || strikerId == nonStrikerId) {
      throw ArgumentError('A valid striker and non-striker are required.');
    }

    return playingBatterIds
        .where((playerId) => playerId > 0)
        .where((playerId) => playerId != strikerId && playerId != nonStrikerId)
        .where((playerId) => !battedPlayerIds.contains(playerId))
        .toSet()
        .toList(growable: false);
  }

  void validateSelection({
    required int replacementBatterId,
    required List<int> playingBatterIds,
    required Set<int> battedPlayerIds,
    required int strikerId,
    required int nonStrikerId,
  }) {
    final eligible = eligibleBatters(
      playingBatterIds: playingBatterIds,
      battedPlayerIds: battedPlayerIds,
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
    );

    if (!eligible.contains(replacementBatterId)) {
      throw ArgumentError(
        'Selected batter is not eligible to replace the dismissed batter.',
      );
    }
  }
}
