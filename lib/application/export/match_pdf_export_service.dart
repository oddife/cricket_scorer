import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/repositories/ball_event_repository.dart';
import '../../domain/innings/models/innings.dart';
import '../../domain/innings/models/innings_recalculation_context.dart';
import '../../domain/innings/models/innings_state.dart';
import '../../domain/innings/services/innings_recalculation_engine.dart';
import '../../domain/matches/enums/toss_decision.dart';
import '../../domain/matches/models/match.dart';
import '../../domain/matches/models/match_player.dart';
import '../../domain/matches/models/match_team.dart';
import '../../domain/matches/services/match_result_service.dart';
import '../../domain/players/models/player.dart';
import '../../domain/scoring/models/ball_event.dart';
import '../../domain/teams/models/team.dart';
import '../../domain/tournaments/models/tournament.dart';

class MatchPdfExportService {
  const MatchPdfExportService();

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
    final sorted = [...innings]
      ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final states = <int, InningsState>{};
    final ballsByInnings = <int, List<BallEvent>>{};
    final resultService = const MatchResultService();

    for (final inning in sorted) {
      final balls = await ballRepository.getForInnings(inning.id);
      ballsByInnings[inning.id] = balls;
      final target = resultService.targetForInnings(
        match: match,
        innings: sorted,
        states: states,
        inningsNumber: inning.inningsNumber,
      );
      states[inning.id] = const InningsRecalculationEngine().recalculate(
        InningsRecalculationContext(
          balls: balls,
          initialStrikerId: inning.openingStrikerId,
          initialNonStrikerId: inning.openingNonStrikerId,
          initialBowlerId: inning.openingBowlerId,
          ballsPerOver: inning.ballsPerOver,
          totalOvers: inning.oversPerInnings,
          target: target,
        ),
      );
    }

    final result = resultService.result(
      match: match,
      innings: sorted,
      states: states,
    );

    final document = pw.Document(title: match.name, author: 'Cricket Scorer');
    final teamById = {for (final team in teams) team.id: team};
    final playerById = {for (final player in players) player.id: player};
    final matchTeamById = {for (final value in matchTeams) value.teamId: value};
    final matchPlayerById = {
      for (final value in matchPlayers) value.playerId: value,
    };

    String teamName(int id) => teamById[id]?.name ?? 'Team $id';
    String playerName(int id) => playerById[id]?.displayName ?? 'Player $id';

    String resultText() {
      if (!result.completed) return 'Match not completed';
      if (result.isTie) return 'MATCH TIED';
      final winner = teamName(result.winnerTeamId!);
      if (result.marginWickets != null) {
        return '$winner won by ${result.marginWickets} wickets';
      }
      if (result.marginRuns != null) {
        return '$winner won by ${result.marginRuns} runs';
      }
      return '$winner won';
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('CRICKET SCORER', style: pw.TextStyle(fontSize: 9)),
            pw.Text('Match Scorecard', style: pw.TextStyle(fontSize: 9)),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Text(
            match.name,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (tournament != null)
            pw.Text(
              'Tournament: ${tournament.name}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          pw.Text('Date: ${_date(match.date)}'),
          if (match.venue != null && match.venue!.trim().isNotEmpty)
            pw.Text('Venue: ${match.venue}'),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  resultText(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (match.tossWinnerTeamId != null && match.tossDecision != null)
                  pw.Text(
                    'Toss: ${teamName(match.tossWinnerTeamId!)} elected '
                    '${_tossLabel(match.tossDecision!)}',
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Teams',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Team', 'Players'],
            data: _teamRows(
              matchTeamById.values.toList(),
              matchPlayers,
              playerName,
              teamName,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 18),
          for (final inning in sorted) ...[
            _inningsSection(
              inning: inning,
              state: states[inning.id]!,
              balls: ballsByInnings[inning.id]!,
              teamName: teamName(inning.battingTeamId),
              playerName: playerName,
              matchPlayers: matchPlayers,
              matchPlayerById: matchPlayerById,
            ),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    return document.save();
  }

  static List<List<String>> _teamRows(
    List<MatchTeam> selectedTeams,
    List<MatchPlayer> matchPlayers,
    String Function(int) playerName,
    String Function(int) teamName,
  ) {
    final byTeam = <int, List<int>>{};
    for (final player in matchPlayers) {
      byTeam.putIfAbsent(player.teamId, () => []).add(player.playerId);
    }
    return selectedTeams
        .map(
          (team) => [
            teamName(team.teamId),
            (byTeam[team.teamId] ?? const <int>[]).map(playerName).join(', '),
          ],
        )
        .toList();
  }

  static pw.Widget _inningsSection({
    required Innings inning,
    required InningsState state,
    required List<BallEvent> balls,
    required String teamName,
    required String Function(int) playerName,
    required List<MatchPlayer> matchPlayers,
    required Map<int, MatchPlayer> matchPlayerById,
  }) {
    final batters = state.batters.values.toList()
      ..sort((a, b) => a.playerId.compareTo(b.playerId));
    final bowlers = state.bowlers.values.toList()
      ..sort((a, b) => a.playerId.compareTo(b.playerId));
    final overs = '${state.completedOvers}.${state.legalBallsInCurrentOver}';
    final batterTeamIds = matchPlayers
        .where((p) => p.teamId == inning.battingTeamId)
        .map((p) => p.playerId)
        .toSet();
    final bowlerTeamIds = matchPlayers
        .where((p) => p.teamId == inning.bowlingTeamId)
        .map((p) => p.playerId)
        .toSet();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Innings ${inning.inningsNumber} — $teamName',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('$overs overs  •  ${state.score}/${state.wickets}'),
        pw.SizedBox(height: 8),
        pw.Text(
          'Batting',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TableHelper.fromTextArray(
          headers: const ['Batter', 'R', 'B', '4s', '6s', 'Status'],
          data: batters
              .where((b) => batterTeamIds.contains(b.playerId))
              .map(
                (b) => [
                  playerName(b.playerId),
                  '${b.runs}',
                  '${b.balls}',
                  '${b.fours}',
                  '${b.sixes}',
                  b.isOut ? 'Out' : 'Not out',
                ],
              )
              .toList(),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Extras: W ${state.wides}  NB ${state.noBalls}  '
          'B ${state.byes}  LB ${state.legByes}',
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Bowling',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TableHelper.fromTextArray(
          headers: const ['Bowler', 'O', 'Runs', 'Wkts'],
          data: bowlers
              .where((b) => bowlerTeamIds.contains(b.playerId))
              .map(
                (b) => [
                  playerName(b.playerId),
                  '${b.legalBalls ~/ inning.ballsPerOver}.${b.legalBalls % inning.ballsPerOver}',
                  '${b.runsConceded}',
                  '${b.wickets}',
                ],
              )
              .toList(),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Ball by ball',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Wrap(
          spacing: 4,
          runSpacing: 3,
          children: [
            for (final ball in balls)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: .5)),
                child: pw.Text(
                  _ballLabel(ball, playerName),
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _ballLabel(BallEvent ball, String Function(int) playerName) {
    final extras = <String>[];
    if (ball.wideRuns > 0) extras.add('W${ball.wideRuns}');
    if (ball.noBallRuns > 0) extras.add('NB${ball.noBallRuns}');
    if (ball.byeRuns > 0) extras.add('B${ball.byeRuns}');
    if (ball.legByeRuns > 0) extras.add('LB${ball.legByeRuns}');
    final runs = ball.batterRuns > 0 ? 'R${ball.batterRuns}' : null;
    final wicketName = ball.wicket?.type.name;
    final detail = [
      ?runs,
      ...extras,
      if (wicketName != null) 'W:$wicketName',
    ].join(' ');
    return '${ball.overNumber + 1}.${ball.legalBallNumber} '
        '${playerName(ball.bowlerId)} → ${playerName(ball.strikerId)}'
        '${detail.isEmpty ? '' : ' $detail'}';
  }

  static String _tossLabel(TossDecision decision) => switch (decision) {
        TossDecision.bat => 'Bat',
        TossDecision.bowl => 'Bowl',
      };

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
