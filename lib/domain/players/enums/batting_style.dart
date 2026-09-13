enum BattingStyle {
  right,
  left,
}

extension BattingStyleX on BattingStyle {
  int get dbValue => switch (this) {
        BattingStyle.right => 0,
        BattingStyle.left => 1,
      };

  String get label => switch (this) {
        BattingStyle.right => 'Right-handed',
        BattingStyle.left => 'Left-handed',
      };
}

BattingStyle battingStyleFromDbValue(int value) {
  return switch (value) {
    0 => BattingStyle.right,
    1 => BattingStyle.left,
    _ => BattingStyle.right,
  };
}
