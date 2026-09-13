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

extension TournamentTypeDatabaseValue on TournamentType {
  int get dbValue {
    switch (this) {
      case TournamentType.league:
        return 0;
      case TournamentType.knockout:
        return 1;
      case TournamentType.leagueAndKnockout:
        return 2;
    }
  }

  static TournamentType fromDbValue(int value) {
    switch (value) {
      case 0:
        return TournamentType.league;
      case 1:
        return TournamentType.knockout;
      case 2:
        return TournamentType.leagueAndKnockout;
      default:
        throw ArgumentError.value(value, 'value', 'Unknown tournament type');
    }
  }
}