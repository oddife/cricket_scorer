class TournamentStanding {
  const TournamentStanding({
    required this.teamId,
    required this.teamName,
    required this.shortName,
    this.played = 0,
    this.won = 0,
    this.lost = 0,
    this.tied = 0,
    this.noResults = 0,
    this.points = 0,
  });

  final int teamId;
  final String teamName;
  final String shortName;
  final int played;
  final int won;
  final int lost;
  final int tied;
  final int noResults;
  final int points;

  TournamentStanding copyWith({
    int? played,
    int? won,
    int? lost,
    int? tied,
    int? noResults,
    int? points,
  }) {
    return TournamentStanding(
      teamId: teamId,
      teamName: teamName,
      shortName: shortName,
      played: played ?? this.played,
      won: won ?? this.won,
      lost: lost ?? this.lost,
      tied: tied ?? this.tied,
      noResults: noResults ?? this.noResults,
      points: points ?? this.points,
    );
  }
}
