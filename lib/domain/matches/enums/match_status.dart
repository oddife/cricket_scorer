enum MatchStatus {
  setup,
  live,
  completed,
  abandoned,
}

extension MatchStatusX on MatchStatus {
  int get dbValue => switch (this) {
        MatchStatus.setup => 0,
        MatchStatus.live => 1,
        MatchStatus.completed => 2,
        MatchStatus.abandoned => 3,
      };

  String get label => switch (this) {
        MatchStatus.setup => 'Setup',
        MatchStatus.live => 'Live',
        MatchStatus.completed => 'Completed',
        MatchStatus.abandoned => 'Abandoned',
      };
}

MatchStatus matchStatusFromDbValue(int value) => switch (value) {
      0 => MatchStatus.setup,
      1 => MatchStatus.live,
      2 => MatchStatus.completed,
      3 => MatchStatus.abandoned,
      _ => MatchStatus.setup,
    };
