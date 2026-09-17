import '../../data/repositories/ball_event_repository.dart';
import '../../data/repositories/innings_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../domain/scoring/enums/delivery_type.dart';
import '../../domain/innings/models/innings.dart';

class PlayerStatistics {
  const PlayerStatistics({
    required this.matches,
    required this.battingInnings,
    required this.runs,
    required this.ballsFaced,
    required this.fours,
    required this.sixes,
    required this.dismissals,
    required this.bowlingInnings,
    required this.legalBallsBowled,
    required this.runsConceded,
    required this.wickets,
    required this.wides,
    required this.noBalls,
  });

  final int matches;
  final int battingInnings;
  final int runs;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final int dismissals;
  final int bowlingInnings;
  final int legalBallsBowled;
  final int runsConceded;
  final int wickets;
  final int wides;
  final int noBalls;

  double get strikeRate => ballsFaced == 0 ? 0 : runs * 100 / ballsFaced;
  double get battingAverage => dismissals == 0 ? 0 : runs / dismissals;
  double get economyRate =>
      legalBallsBowled == 0 ? 0 : runsConceded * 6 / legalBallsBowled;
  String get oversBowled =>
      '${legalBallsBowled ~/ 6}.${legalBallsBowled % 6}';
}

class PlayerStatisticsService {
  const PlayerStatisticsService({
    required this.matchRepository,
    required this.inningsRepository,
    required this.ballEventRepository,
  });

  final MatchRepository matchRepository;
  final InningsRepository inningsRepository;
  final BallEventRepository ballEventRepository;

  Future<PlayerStatistics> load(int playerId) async {
    final matches = await matchRepository.getAll();
    final innings = <Innings>[];
    for (final match in matches) {
      innings.addAll(await inningsRepository.getForMatch(match.id));
    }

    final matchIds = <int>{};
    final battingInnings = <int>{};
    final bowlingInnings = <int>{};
    var runs = 0;
    var ballsFaced = 0;
    var fours = 0;
    var sixes = 0;
    var dismissals = 0;
    var legalBallsBowled = 0;
    var runsConceded = 0;
    var wickets = 0;
    var wides = 0;
    var noBalls = 0;

    for (final inning in innings) {
      final balls = await ballEventRepository.getForInnings(inning.id);
      for (final ball in balls) {
        if (ball.strikerId == playerId) {
          matchIds.add(inning.matchId);
          battingInnings.add(inning.id);
          runs += ball.batterRuns;
          if (ball.deliveryType != DeliveryType.wide) ballsFaced++;
          if (ball.batterRuns == 4) fours++;
          if (ball.batterRuns == 6) sixes++;
        }

        if (ball.wicket?.dismissedPlayerId == playerId) {
          matchIds.add(inning.matchId);
          battingInnings.add(inning.id);
          dismissals++;
        }

        if (ball.bowlerId == playerId) {
          matchIds.add(inning.matchId);
          bowlingInnings.add(inning.id);
          if (ball.isLegalBall) legalBallsBowled++;
          runsConceded += ball.totalRuns - ball.byeRuns - ball.legByeRuns;
          wides += ball.wideRuns;
          noBalls += ball.noBallRuns;
          if (ball.wicket?.creditedToBowler == true) wickets++;
        }
      }
    }

    return PlayerStatistics(
      matches: matchIds.length,
      battingInnings: battingInnings.length,
      runs: runs,
      ballsFaced: ballsFaced,
      fours: fours,
      sixes: sixes,
      dismissals: dismissals,
      bowlingInnings: bowlingInnings.length,
      legalBallsBowled: legalBallsBowled,
      runsConceded: runsConceded,
      wickets: wickets,
      wides: wides,
      noBalls: noBalls,
    );
  }
}
