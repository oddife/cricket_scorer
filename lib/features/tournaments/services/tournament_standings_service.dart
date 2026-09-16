import '../../../data/repositories/ball_event_repository.dart';
import '../../../data/repositories/innings_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/tournament_points_repository.dart';
import '../../../data/repositories/tournament_team_repository.dart';
import '../../../domain/matches/enums/match_status.dart';
import '../../../domain/matches/models/match.dart';
import '../../../domain/teams/models/team.dart';
import '../../../domain/tournaments/models/tournament_points_rules.dart';
import '../../../domain/tournaments/models/tournament_standing.dart';

class TournamentStandingsService {
  TournamentStandingsService({
    required this.matchRepository,
    required this.inningsRepository,
    required this.ballEventRepository,
    required this.teamRepository,
    required this.tournamentTeamRepository,
    required this.pointsRepository,
  });

  final MatchRepository matchRepository;
  final InningsRepository inningsRepository;
  final BallEventRepository ballEventRepository;
  final TeamRepository teamRepository;
  final TournamentTeamRepository tournamentTeamRepository;
  final TournamentPointsRepository pointsRepository;

  Future<List<TournamentStanding>> calculate(int tournamentId) async {
    final teams = await tournamentTeamRepository.getTeams(tournamentId);
    final allTeams = {for (final team in await teamRepository.getAll()) team.id: team};
    final rules = await pointsRepository.get(tournamentId);
    final matches = (await matchRepository.getAll())
        .where((match) => match.tournamentId == tournamentId &&
            (match.status == MatchStatus.completed || match.status == MatchStatus.abandoned))
        .toList();

    final rows = <int, _MutableStanding>{};
    for (final team in teams) {
      rows[team.id] = _MutableStanding(team);
    }

    for (final match in matches) {
      final matchTeams = await matchRepository.getTeams(match.id);
      if (matchTeams.length != 2) continue;
      final teamA = matchTeams[0].teamId;
      final teamB = matchTeams[1].teamId;
      if (!rows.containsKey(teamA) || !rows.containsKey(teamB)) continue;

      final result = await _resultFor(match, teamA, teamB);
      switch (result) {
        case _MatchResult.teamA:
          _record(rows[teamA]!, won: true, points: rules.winPoints);
          _record(rows[teamB]!, lost: true, points: rules.lossPoints);
        case _MatchResult.teamB:
          _record(rows[teamA]!, lost: true, points: rules.lossPoints);
          _record(rows[teamB]!, won: true, points: rules.winPoints);
        case _MatchResult.tie:
          _record(rows[teamA]!, tied: true, points: rules.tiePoints);
          _record(rows[teamB]!, tied: true, points: rules.tiePoints);
        case _MatchResult.noResult:
          _record(rows[teamA]!, noResult: true, points: rules.noResultPoints);
          _record(rows[teamB]!, noResult: true, points: rules.noResultPoints);
      }
    }

    final standings = rows.values
        .map((row) => row.value)
        .toList()
      ..sort((a, b) {
        final points = b.points.compareTo(a.points);
        if (points != 0) return points;
        final wins = b.won.compareTo(a.won);
        if (wins != 0) return wins;
        return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
      });

    // Keep the lookup above explicit so a stale tournament-team reference never
    // creates a blank team row.
    return standings.where((standing) => allTeams.containsKey(standing.teamId)).toList(growable: false);
  }

  Future<_MatchResult> _resultFor(Match match, int teamA, int teamB) async {
    if (match.status == MatchStatus.abandoned) return _MatchResult.noResult;

    final innings = await inningsRepository.getForMatch(match.id);
    final totals = <int, int>{teamA: 0, teamB: 0};
    for (final inning in innings) {
      if (!totals.containsKey(inning.battingTeamId)) continue;
      final events = await ballEventRepository.getForInnings(inning.id);
      totals[inning.battingTeamId] = totals[inning.battingTeamId]! +
          events.fold<int>(0, (sum, event) => sum + event.totalRuns);
    }

    if (totals[teamA] == totals[teamB]) return _MatchResult.tie;
    return totals[teamA]! > totals[teamB]!
        ? _MatchResult.teamA
        : _MatchResult.teamB;
  }

  void _record(
    _MutableStanding row, {
    bool won = false,
    bool lost = false,
    bool tied = false,
    bool noResult = false,
    required int points,
  }) {
    row.played++;
    if (won) row.won++;
    if (lost) row.lost++;
    if (tied) row.tied++;
    if (noResult) row.noResults++;
    row.points += points;
  }
}

class _MutableStanding {
  _MutableStanding(Team team)
      : value = TournamentStanding(
          teamId: team.id,
          teamName: team.name,
          shortName: team.shortName,
        );

  TournamentStanding value;

  int get played => value.played;
  set played(int value) => this.value = this.value.copyWith(played: value);
  int get won => value.won;
  set won(int value) => this.value = this.value.copyWith(won: value);
  int get lost => value.lost;
  set lost(int value) => this.value = this.value.copyWith(lost: value);
  int get tied => value.tied;
  set tied(int value) => this.value = this.value.copyWith(tied: value);
  int get noResults => value.noResults;
  set noResults(int value) => this.value = this.value.copyWith(noResults: value);
  int get points => value.points;
  set points(int value) => this.value = this.value.copyWith(points: value);
}

enum _MatchResult { teamA, teamB, tie, noResult }
