import '../models/match.dart';
import '../../innings/models/innings.dart';
import '../../innings/models/innings_state.dart';

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
      final first = states[1];
      return first == null ? null : first.score + 1;
    }

    if (match.inningsCount == 4 && inningsNumber == 4) {
      final first = states[1];
      final second = states[2];
      final third = states[3];
      if (first == null || second == null || third == null) return null;
      final firstTeam = innings.firstWhere((i) => i.inningsNumber == 1).battingTeamId;
      final secondTeam = innings.firstWhere((i) => i.inningsNumber == 2).battingTeamId;
      final thirdTeam = innings.firstWhere((i) => i.inningsNumber == 3).battingTeamId;
      final teamA = firstTeam;
      final teamB = secondTeam;
      if (thirdTeam != teamA) return null;
      final teamAScore = first.score + third.score;
      final teamBFirst = second.score;
      return teamAScore - teamBFirst + 1;
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
    for (final entry in states.entries) {
      final matchInnings = innings.where((i) => i.id == entry.key);
      if (matchInnings.isEmpty) continue;
      final teamId = matchInnings.first.battingTeamId;
      scoresByTeam[teamId] = (scoresByTeam[teamId] ?? 0) + entry.value.score;
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
    if (innings.length < match.inningsCount) {
      return const MatchResult(completed: false);
    }

    final finalInnings = states[innings.firstWhere((i) => i.inningsNumber == match.inningsCount).id];
    if (finalInnings == null || !finalInnings.inningsComplete) {
      return const MatchResult(completed: false);
    }

    final totals = <int, int>{};
    for (final i in innings) {
      final state = states[i.id];
      if (state == null) return const MatchResult(completed: false);
      totals[i.battingTeamId] = (totals[i.battingTeamId] ?? 0) + state.score;
    }

    final teamIds = totals.keys.toList();
    if (teamIds.length != 2) return const MatchResult(completed: false);
    final a = totals[teamIds[0]]!;
    final b = totals[teamIds[1]]!;
    if (a == b) return const MatchResult(completed: true, isTie: true);

    final winner = a > b ? teamIds[0] : teamIds[1];
    return MatchResult(
      completed: true,
      winnerTeamId: winner,
      marginRuns: (a - b).abs(),
    );
  }
}
