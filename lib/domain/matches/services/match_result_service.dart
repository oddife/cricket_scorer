import '../../innings/enums/innings_status.dart';
import '../../innings/models/innings.dart';
import '../../innings/models/innings_state.dart';
import '../models/match.dart';

class MatchResult {
  const MatchResult({
    required this.completed,
    this.winnerTeamId,
    this.isTie = false,
    this.marginRuns,
    this.marginWickets,
  });

  final bool completed;
  final int? winnerTeamId;
  final bool isTie;
  final int? marginRuns;
  final int? marginWickets;
}

class MatchResultService {
  const MatchResultService();

  int? targetForInnings({
    required Match match,
    required List<Innings> innings,
    required Map<int, InningsState> states,
    required int inningsNumber,
  }) {
    if (match.inningsCount == 2 && inningsNumber == 2) {
      final first = states[innings.firstWhere((i) => i.inningsNumber == 1).id];
      return first == null ? null : first.score + 1;
    }

    if (match.inningsCount == 4 && inningsNumber == 4) {
      final firstInnings = innings.firstWhere((i) => i.inningsNumber == 1);
      final secondInnings = innings.firstWhere((i) => i.inningsNumber == 2);
      final thirdInnings = innings.firstWhere((i) => i.inningsNumber == 3);
      final first = states[firstInnings.id];
      final second = states[secondInnings.id];
      final third = states[thirdInnings.id];
      if (first == null || second == null || third == null) return null;
      if (thirdInnings.battingTeamId != firstInnings.battingTeamId) return null;
      final target = first.score + third.score - second.score + 1;
      return target < 1 ? 1 : target;
    }

    return null;
  }

  int? leadOrDeficitAfterInnings({
    required List<Innings> innings,
    required Map<int, InningsState> states,
    required int inningsNumber,
  }) {
    if (inningsNumber < 2 || inningsNumber > 4) return null;
    final scoresByTeam = <int, int>{};
    for (final inning in innings) {
      if (inning.inningsNumber > inningsNumber) continue;
      final state = states[inning.id];
      if (state == null) continue;
      scoresByTeam[inning.battingTeamId] = (scoresByTeam[inning.battingTeamId] ?? 0) + state.score;
    }
    final current = innings.firstWhere((i) => i.inningsNumber == inningsNumber).battingTeamId;
    final other = scoresByTeam.keys.where((id) => id != current).firstOrNull;
    if (other == null) return null;
    return (scoresByTeam[current] ?? 0) - (scoresByTeam[other] ?? 0);
  }

  MatchResult result({
    required Match match,
    required List<Innings> innings,
    required Map<int, InningsState> states,
  }) {
    if (innings.length < match.inningsCount) return const MatchResult(completed: false);

    final sorted = [...innings]..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final finalInnings = states[sorted.last.id];
    if (finalInnings == null) return const MatchResult(completed: false);
    final finalInningsEnded = sorted.last.status == InningsStatus.ended;

    if (match.inningsCount == 2) {
      final first = states[sorted[0].id]!;
      final second = states[sorted[1].id]!;

      if (second.score > first.score) {
        final wicketsAvailable = match.playersPerTeam > 0 ? match.playersPerTeam - 1 : 0;
        final wicketsRemaining = (wicketsAvailable - second.wickets).clamp(0, wicketsAvailable).toInt();
        return MatchResult(completed: true, winnerTeamId: sorted[1].battingTeamId, marginWickets: wicketsRemaining);
      }

      if (!finalInnings.inningsComplete && !finalInningsEnded) {
        return const MatchResult(completed: false);
      }

      if (first.score == second.score) return const MatchResult(completed: true, isTie: true);

      return MatchResult(
        completed: true,
        winnerTeamId: sorted[0].battingTeamId,
        marginRuns: first.score - second.score,
      );
    }

    final totals = <int, int>{};
    for (final inning in sorted) {
      final state = states[inning.id];
      if (state == null) return const MatchResult(completed: false);
      totals[inning.battingTeamId] = (totals[inning.battingTeamId] ?? 0) + state.score;
    }

    final teamIds = totals.keys.toList();
    if (teamIds.length != 2) return const MatchResult(completed: false);

    final finalTeam = sorted.last.battingTeamId;
    final otherTeam = teamIds.firstWhere((id) => id != finalTeam);

    if (totals[finalTeam]! > totals[otherTeam]!) {
      final wicketsAvailable = match.playersPerTeam > 0 ? match.playersPerTeam - 1 : 0;
      final finalState = states[sorted.last.id]!;
      final wicketsRemaining = (wicketsAvailable - finalState.wickets).clamp(0, wicketsAvailable).toInt();
      return MatchResult(completed: true, winnerTeamId: finalTeam, marginWickets: wicketsRemaining);
    }

    if (!finalInnings.inningsComplete && !finalInningsEnded) {
      return const MatchResult(completed: false);
    }

    final firstTotal = totals[teamIds[0]]!;
    final secondTotal = totals[teamIds[1]]!;
    if (firstTotal == secondTotal) return const MatchResult(completed: true, isTie: true);

    return MatchResult(
      completed: true,
      winnerTeamId: otherTeam,
      marginRuns: totals[otherTeam]! - totals[finalTeam]!,
    );
  }
}
