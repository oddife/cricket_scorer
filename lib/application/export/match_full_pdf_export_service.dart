import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/repositories/ball_event_repository.dart';
import '../../domain/innings/models/innings.dart';
import '../../domain/innings/models/innings_recalculation_context.dart';
import '../../domain/innings/models/innings_state.dart';
import '../../domain/innings/services/innings_recalculation_engine.dart';
import '../../domain/matches/models/match.dart';
import '../../domain/matches/models/match_player.dart';
import '../../domain/matches/models/match_team.dart';
import '../../domain/matches/services/match_result_service.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/players/models/player.dart';
import '../../domain/scoring/models/ball_event.dart';
import '../../domain/teams/models/team.dart';
import '../../domain/tournaments/models/tournament.dart';

class MatchFullPdfExportService {
  const MatchFullPdfExportService();

  Future<Uint8List> build({
    required Match match,
    required List<Innings> innings,
    required List<MatchTeam> matchTeams,
    required List<MatchPlayer> matchPlayers,
    required List<Team> teams,
    required List<Player> players,
    Tournament? tournament,
    required BallEventRepository ballRepository,
  }) async {
    final sorted = [...innings]..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final states = <int, InningsState>{};
    final ballsByInnings = <int, List<BallEvent>>{};
    final resultService = const MatchResultService();
    for (final inning in sorted) {
      final balls = await ballRepository.getForInnings(inning.id);
      ballsByInnings[inning.id] = balls;
      final target = resultService.targetForInnings(match: match, innings: sorted, states: states, inningsNumber: inning.inningsNumber);
      states[inning.id] = const InningsRecalculationEngine().recalculate(InningsRecalculationContext(
        balls: balls,
        initialStrikerId: inning.openingStrikerId,
        initialNonStrikerId: inning.openingNonStrikerId,
        initialBowlerId: inning.openingBowlerId,
        ballsPerOver: inning.ballsPerOver,
        totalOvers: inning.oversPerInnings,
        target: target,
      ));
    }
    final result = resultService.result(match: match, innings: sorted, states: states);
    final teamById = {for (final t in teams) t.id: t};
    final playerById = {for (final p in players) p.id: p};
    final matchTeamById = {for (final t in matchTeams) t.teamId: t};
    String teamName(int id) => teamById[id]?.name ?? 'Team $id';
    String playerName(int id) => playerById[id]?.displayName ?? 'Player $id';
    String resultText() {
      if (!result.completed) return 'Match not completed';
      if (result.isTie) return 'MATCH TIED';
      final winner = teamName(result.winnerTeamId!);
      if (result.marginWickets != null) return '$winner won by ${result.marginWickets} wickets';
      if (result.marginRuns != null) return '$winner won by ${result.marginRuns} runs';
      return '$winner won';
    }

    final document = pw.Document(title: '${match.name} - Full Scorecard', author: 'Cricket Scorer');
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('CRICKET SCORER', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('Full Match Scorecard', style: const pw.TextStyle(fontSize: 9)),
      ]),
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8))),
      build: (context) => [
        pw.SizedBox(height: 12),
        pw.Text(match.name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        if (tournament != null) pw.Text('Tournament: ${tournament.name}'),
        pw.Text('Date: ${_date(match.date)}'),
        if (match.venue != null && match.venue!.trim().isNotEmpty) pw.Text('Venue: ${match.venue}'),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(resultText(), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            if (match.tossWinnerTeamId != null && match.tossDecision != null) pw.Text('Toss: ${teamName(match.tossWinnerTeamId!)} elected ${match.tossDecision!.label}'),
          ]),
        ),
        pw.SizedBox(height: 14),
        pw.Text('Teams', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(headers: const ['Team', 'Players'], data: _teamRows(matchTeamById.values.toList(), matchPlayers, playerName, teamName), cellStyle: const pw.TextStyle(fontSize: 8), headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 14),
        for (final inning in sorted) ...[
          _inningsSection(inning, teamName(inning.battingTeamId), states[inning.id]!, ballsByInnings[inning.id]!, playerName, matchPlayers),
          pw.SizedBox(height: 16),
        ],
      ],
    ));
    return document.save();
  }

  static List<List<String>> _teamRows(List<MatchTeam> selected, List<MatchPlayer> matchPlayers, String Function(int) playerName, String Function(int) teamName) {
    final byTeam = <int, List<int>>{};
    for (final p in matchPlayers) byTeam.putIfAbsent(p.teamId, () => []).add(p.playerId);
    return selected.map((t) => [teamName(t.teamId), (byTeam[t.teamId] ?? const <int>[]).map(playerName).join(', ')]).toList();
  }

  static pw.Widget _inningsSection(Innings inning, String teamName, InningsState state, List<BallEvent> balls, String Function(int) playerName, List<MatchPlayer> matchPlayers) {
    final batterIds = matchPlayers.where((p) => p.teamId == inning.battingTeamId).map((p) => p.playerId).toSet();
    final bowlerIds = matchPlayers.where((p) => p.teamId == inning.bowlingTeamId).map((p) => p.playerId).toSet();
    final batters = state.batters.values.where((b) => batterIds.contains(b.playerId)).toList()..sort((a, b) => a.playerId.compareTo(b.playerId));
    final bowlers = state.bowlers.values.where((b) => bowlerIds.contains(b.playerId)).toList()..sort((a, b) => a.playerId.compareTo(b.playerId));
    final overs = '${state.completedOvers}.${state.legalBallsInCurrentOver}';
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Innings ${inning.inningsNumber} - $teamName', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
      pw.Text('$overs overs | ${state.score}/${state.wickets}'),
      pw.SizedBox(height: 7),
      pw.Text('Batting', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(headers: const ['Batter', 'R', 'B', '4s', '6s', 'Status'], data: batters.map((b) => [playerName(b.playerId), '${b.runs}', '${b.balls}', '${b.fours}', '${b.sixes}', b.isOut ? 'Out' : 'Not out']).toList(), cellStyle: const pw.TextStyle(fontSize: 8), headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 5),
      pw.Text('Extras: W ${state.wides}  NB ${state.noBalls}  B ${state.byes}  LB ${state.legByes}'),
      pw.SizedBox(height: 8),
      pw.Text('Bowling', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(headers: const ['Bowler', 'O', 'Runs', 'Wkts'], data: bowlers.map((b) => [playerName(b.playerId), '${b.legalBalls ~/ inning.ballsPerOver}.${b.legalBalls % inning.ballsPerOver}', '${b.runsConceded}', '${b.wickets}']).toList(), cellStyle: const pw.TextStyle(fontSize: 8), headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 9),
      pw.Text('Detailed ball-by-ball', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(headers: const ['Ball', 'Bowler', 'Batter', 'Result'], data: balls.map((b) => ['${b.overNumber}.${b.legalBallNumber}', playerName(b.bowlerId), playerName(b.strikerId), _ballResult(b)]).toList(), cellStyle: const pw.TextStyle(fontSize: 7), headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2)),
    ]);
  }

  static String _ballResult(BallEvent ball) {
    final parts = <String>[];
    if (ball.wideRuns > 0) parts.add(ball.wideRuns == 1 ? 'Wd' : 'Wd ${ball.wideRuns}');
    if (ball.noBallRuns > 0) parts.add(ball.noBallRuns == 1 ? 'Nb' : 'Nb ${ball.noBallRuns}');
    if (ball.byeRuns > 0) parts.add('B${ball.byeRuns}');
    if (ball.legByeRuns > 0) parts.add('LB${ball.legByeRuns}');
    if (ball.batterRuns > 0) parts.add('${ball.batterRuns}');
    if (ball.wicket != null) parts.add('W (${ball.wicket!.type.name})');
    return parts.isEmpty ? '.' : parts.join(' ');
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
