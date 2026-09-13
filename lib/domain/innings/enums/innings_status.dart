enum InningsStatus {
  setup,
  live,
  completed,
  ended;

  int get dbValue => switch (this) {
        InningsStatus.setup => 0,
        InningsStatus.live => 1,
        InningsStatus.completed => 2,
        InningsStatus.ended => 3,
      };

  static InningsStatus fromDb(int value) => switch (value) {
        0 => InningsStatus.setup,
        1 => InningsStatus.live,
        2 => InningsStatus.completed,
        3 => InningsStatus.ended,
        _ => InningsStatus.setup,
      };
}
