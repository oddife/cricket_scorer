import '../enums/run_out_end.dart';

class RunOutResolution {
  const RunOutResolution({
    required this.strikerId,
    required this.nonStrikerId,
    required this.dismissedPlayerId,
    required this.remainingBatterId,
  });

  final int strikerId;
  final int nonStrikerId;
  final int dismissedPlayerId;
  final int remainingBatterId;
}

class RunOutResolver {
  const RunOutResolver();

  RunOutResolution resolve({
    required int strikerId,
    required int nonStrikerId,
    required RunOutEnd runOutEnd,
    required int completedRuns,
    required bool crossedBeforeWicket,
  }) {
    if (strikerId <= 0 || nonStrikerId <= 0 || strikerId == nonStrikerId) {
      throw ArgumentError('A valid striker and non-striker are required.');
    }
    if (completedRuns < 0) {
      throw ArgumentError.value(completedRuns, 'completedRuns');
    }

    var strikerAtEnd = strikerId;
    var nonStrikerAtEnd = nonStrikerId;

    // Completed runs move the batters between ends.
    if (completedRuns.isOdd) {
      final temp = strikerAtEnd;
      strikerAtEnd = nonStrikerAtEnd;
      nonStrikerAtEnd = temp;
    }

    // The run in progress is only relevant to the positions at the instant
    // the wicket is broken. Under Law 18.12, crossing before that incident
    // determines which end the not-out batter returns to.
    if (crossedBeforeWicket) {
      final temp = strikerAtEnd;
      strikerAtEnd = nonStrikerAtEnd;
      nonStrikerAtEnd = temp;
    }

    final dismissedPlayerId = switch (runOutEnd) {
      RunOutEnd.striker => strikerAtEnd,
      RunOutEnd.nonStriker => nonStrikerAtEnd,
    };
    final remainingBatterId = dismissedPlayerId == strikerAtEnd
        ? nonStrikerAtEnd
        : strikerAtEnd;

    return RunOutResolution(
      strikerId: strikerAtEnd,
      nonStrikerId: nonStrikerAtEnd,
      dismissedPlayerId: dismissedPlayerId,
      remainingBatterId: remainingBatterId,
    );
  }
}
