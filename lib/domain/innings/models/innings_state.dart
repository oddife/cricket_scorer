class BatterInningsState {
  const BatterInningsState({
    required this.playerId,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.isOut,
  });

  final int playerId;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
}

class BowlerInningsState {
  const BowlerInningsState({
    required this.playerId,
    required this.legalBalls,
    required this.runsConceded,
    required this.wickets,
  });

  final int playerId;
  final int legalBalls;
  final int runsConceded;
  final int wickets;
}

class InningsState {
  const InningsState({
    required this.score,
    required this.wickets,
    required this.legalBalls,
    required this.ballsPerOver,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    required this.wides,
    required this.noBalls,
    required this.byes,
    required this.legByes,
    required this.batters,
    required this.bowlers,
    required this.ballCount,
    required this.requiresBatterReplacement,
    required this.targetReached,
    required this.oversComplete,
    required this.wicketsComplete,
  });

  final int score;
  final int wickets;
  final int legalBalls;
  final int ballsPerOver;
  final int strikerId;
  final int nonStrikerId;
  final int bowlerId;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final Map<int, BatterInningsState> batters;
  final Map<int, BowlerInningsState> bowlers;
  final int ballCount;
  final bool requiresBatterReplacement;
  final bool targetReached;
  final bool oversComplete;
  final bool wicketsComplete;

  int get completedOvers => legalBalls ~/ ballsPerOver;
  int get legalBallsInCurrentOver => legalBalls % ballsPerOver;
  bool get inningsComplete =>
      targetReached || oversComplete || wicketsComplete;
}
