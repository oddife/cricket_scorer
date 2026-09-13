enum BowlingStyle {
  right,
  left,
}

extension BowlingStyleX on BowlingStyle {
  int get dbValue => switch (this) {
        BowlingStyle.right => 0,
        BowlingStyle.left => 1,
      };

  String get label => switch (this) {
        BowlingStyle.right => 'Right-arm',
        BowlingStyle.left => 'Left-arm',
      };
}

BowlingStyle bowlingStyleFromDbValue(int value) {
  return switch (value) {
    0 => BowlingStyle.right,
    1 => BowlingStyle.left,
    _ => BowlingStyle.right,
  };
}
