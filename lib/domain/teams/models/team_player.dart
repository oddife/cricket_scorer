class TeamPlayer {
  const TeamPlayer({
    required this.id,
    required this.teamId,
    required this.playerId,
    this.jerseyNumber,
    this.isActive = true,
  });

  final int id;
  final int teamId;
  final int playerId;
  final int? jerseyNumber;
  final bool isActive;
}
