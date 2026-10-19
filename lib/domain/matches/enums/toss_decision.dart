enum TossDecision {
  bat,
  bowl,
}

extension TossDecisionX on TossDecision {
  int get dbValue => switch (this) {
        TossDecision.bat => 0,
        TossDecision.bowl => 1,
      };

  String get label => switch (this) {
        TossDecision.bat => 'Bat',
        TossDecision.bowl => 'Bowl',
      };
}

TossDecision tossDecisionFromDbValue(int value) => switch (value) {
      0 => TossDecision.bat,
      1 => TossDecision.bowl,
      _ => TossDecision.bat,
    };
