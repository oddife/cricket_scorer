class TournamentPointsRules {
  const TournamentPointsRules({
    required this.tournamentId,
    this.winPoints = 2,
    this.tiePoints = 1,
    this.noResultPoints = 1,
    this.lossPoints = 0,
  });

  final int tournamentId;
  final int winPoints;
  final int tiePoints;
  final int noResultPoints;
  final int lossPoints;

  TournamentPointsRules copyWith({
    int? tournamentId,
    int? winPoints,
    int? tiePoints,
    int? noResultPoints,
    int? lossPoints,
  }) {
    return TournamentPointsRules(
      tournamentId: tournamentId ?? this.tournamentId,
      winPoints: winPoints ?? this.winPoints,
      tiePoints: tiePoints ?? this.tiePoints,
      noResultPoints: noResultPoints ?? this.noResultPoints,
      lossPoints: lossPoints ?? this.lossPoints,
    );
  }
}
