enum TournamentType {
  league,
  knockout,
  leagueAndKnockout,
}

extension TournamentTypeLabel on TournamentType {
  String get label {
    switch (this) {
      case TournamentType.league:
        return 'League';
      case TournamentType.knockout:
        return 'Knockout';
      case TournamentType.leagueAndKnockout:
        return 'League + Knockout';
    }
  }
}