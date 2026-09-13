enum MatchTeamSlot {
  teamA,
  teamB,
}

extension MatchTeamSlotX on MatchTeamSlot {
  int get dbValue => switch (this) {
        MatchTeamSlot.teamA => 0,
        MatchTeamSlot.teamB => 1,
      };

  String get label => switch (this) {
        MatchTeamSlot.teamA => 'Team A',
        MatchTeamSlot.teamB => 'Team B',
      };
}

MatchTeamSlot matchTeamSlotFromDbValue(int value) => switch (value) {
      0 => MatchTeamSlot.teamA,
      1 => MatchTeamSlot.teamB,
      _ => MatchTeamSlot.teamA,
    };
