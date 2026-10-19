class MatchPlayer {
  const MatchPlayer({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.playerId,
    this.isPlaying = false,
    this.battingOrder,
  });

  final int id;
  final int matchId;
  final int teamId;
  final int playerId;
  final bool isPlaying;
  final int? battingOrder;
}
