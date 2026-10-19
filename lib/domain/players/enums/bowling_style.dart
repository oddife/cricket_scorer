enum BowlingStyle {
  right('Right-arm', 0),
  left('Left-arm', 1);

  const BowlingStyle(this.label, this.dbValue);

  final String label;
  final int dbValue;
}

BowlingStyle bowlingStyleFromDbValue(int value) {
  return switch (value) {
    0 => BowlingStyle.right,
    1 => BowlingStyle.left,
    _ => BowlingStyle.right,
  };
}
