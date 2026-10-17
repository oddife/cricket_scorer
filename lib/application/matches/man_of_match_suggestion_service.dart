import '../../domain/innings/models/innings.dart';
import '../../domain/scoring/models/ball_event.dart';
import '../../domain/scoring/enums/delivery_type.dart';

/// A match-wide player's recorded contribution, used to suggest a Man of the Match.
class ManOfMatchContribution {
  const ManOfMatchContribution({
    required this.playerId,
    required this.runs,
    required this.ballsFaced,
    required this.wickets,
    required this.runsConceded,
    required this.fieldingDismissals,
  });

  final int playerId;
  final int runs;
  final int ballsFaced;
  final int wickets;
  final int runsConceded;
  final int fieldingDismissals;

  /// A transparent heuristic for ranking suggestions, not an official award.
  /// Batting runs count one point, a bowler-credited wicket 20, and a recorded
  /// fielder dismissal 10. Actual figures are shown to the scorer for review.
  int get impactScore => runs + wickets * 20 + fieldingDismissals * 10;
}

class ManOfMatchSuggestionService {
  const ManOfMatchSuggestionService();

  ManOfMatchContribution? suggest({
    required List<Innings> innings,
    required Map<int, List<BallEvent>> ballsByInnings,
  }) {
    final totals = <int, _MutableContribution>{};

    _MutableContribution forPlayer(int id) =>
        totals.putIfAbsent(id, () => _MutableContribution(id));

    for (final inning in innings) {
      for (final ball in ballsByInnings[inning.id] ?? const <BallEvent>[]) {
        if (ball.strikerId > 0) {
          final batter = forPlayer(ball.strikerId);
          batter.runs += ball.batterRuns;
          if (ball.deliveryType != DeliveryType.wide) {
            batter.ballsFaced++;
          }
        }

        if (ball.bowlerId > 0) {
          final bowler = forPlayer(ball.bowlerId);
          bowler.runsConceded +=
              ball.totalRuns - ball.byeRuns - ball.legByeRuns;
          if (ball.wicket?.creditedToBowler == true) {
            bowler.wickets++;
          }
        }

        final fielderId = ball.wicket?.fielderId;
        if (fielderId != null && fielderId > 0) {
          forPlayer(fielderId).fieldingDismissals++;
        }
      }
    }

    final ranked = totals.values
        .where((player) =>
            player.runs > 0 ||
            player.wickets > 0 ||
            player.fieldingDismissals > 0)
        .map((player) => player.toContribution())
        .toList()
      ..sort((a, b) {
        final scoreOrder = b.impactScore.compareTo(a.impactScore);
        if (scoreOrder != 0) return scoreOrder;
        final wicketOrder = b.wickets.compareTo(a.wickets);
        if (wicketOrder != 0) return wicketOrder;
        final runOrder = b.runs.compareTo(a.runs);
        if (runOrder != 0) return runOrder;
        return a.playerId.compareTo(b.playerId);
      });

    return ranked.isEmpty ? null : ranked.first;
  }
}

class _MutableContribution {
  _MutableContribution(this.playerId);

  final int playerId;
  int runs = 0;
  int ballsFaced = 0;
  int wickets = 0;
  int runsConceded = 0;
  int fieldingDismissals = 0;

  ManOfMatchContribution toContribution() => ManOfMatchContribution(
        playerId: playerId,
        runs: runs,
        ballsFaced: ballsFaced,
        wickets: wickets,
        runsConceded: runsConceded,
        fieldingDismissals: fieldingDismissals,
      );
}
