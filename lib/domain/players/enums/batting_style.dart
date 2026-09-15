enum BattingStyle {
  right('Right-handed', 0),
  left('Left-handed', 1);

  const BattingStyle(this.label, this.dbValue);

  final String label;
  final int dbValue;
}

BattingStyle battingStyleFromDbValue(int value) {
  return switch (value) {
    0 => BattingStyle.right,
    1 => BattingStyle.left,
    _ => BattingStyle.right,
  };
}
