import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

class MatchFullPdfExportService {
  MatchFullPdfExportService({
    required this._ballEventRepository,
    required this._recalculationEngine,
    required this._matchResultService,
  });

  final BallEventRepository _ballEventRepository;
  final InningsRecalculationEngine _recalculationEngine;
  final MatchResultService _matchResultService;

  Future<Uint8List> generate({
    required Match match,
    required List<Innings> innings,
    required List<MatchTeam> matchTeams,
    required List<MatchPlayer> matchPlayers,
    required List<Team> teams,
    required List<Player> players,
    Tournament? tournament,
  }) async {
    final inningsStates = <InningsState>[];
    final inningsEvents = <int, List<BallEvent>>{};
    for (final inning in innings) {
      final events = await _ballEventRepository.getForInnings(inning.id);
      inningsEvents[inning.id] = events;
      inningsStates.add(_recalculationEngine.recalculate(
        InningsRecalculationContext(
          balls: events,
          initialStrikerId: inning.openingStrikerId,
          initialNonStrikerId: inning.openingNonStrikerId,
          initialBowlerId: inning.openingBowlerId,
          ballsPerOver: inning.ballsPerOver,
          totalOvers: inning.oversPerInnings,
          maxWickets: match.playersPerTeam - 1,
        ),
      ));
    }

    String teamName(int teamId) {
      final team = teams.where((t) => t.id == teamId).firstOrNull;
      return team?.name ?? 'Team $teamId';
    }

    String playerName(int playerId) {
      final player = players.where((p) => p.id == playerId).firstOrNull;
      return player?.displayName ?? player?.name ?? 'Player $playerId';
    }

    final matchStateByInningsId = <int, InningsState>{};
    for (var i = 0; i < innings.length; i++) {
      matchStateByInningsId[innings[i].id] = inningsStates[i];
    }
    final result = _matchResultService.result(
      match: match,
      innings: innings,
      states: matchStateByInningsId,
    );

    String resultText() {
      if (!result.completed) return 'Match in progress';
      if (result.isTie) return 'Match tied';
      if (result.winnerTeamId == null) return 'Match completed';
      final winner = teamName(result.winnerTeamId!);
      if (result.marginWickets != null) {
        return '$winner won by ${result.marginWickets} wickets';
      }
      if (result.marginRuns != null) {
        return '$winner won by ${result.marginRuns} runs';
      }
      return '$winner won';
    }

    String eventResult(BallEvent b) {
      final parts = <String>[];
      if (b.wideRuns > 0) {
        parts.add(b.wideRuns == 1 ? 'Wd' : 'Wd ${b.wideRuns}');
      }
      if (b.noBallRuns > 0) {
        parts.add(b.noBallRuns == 1 ? 'Nb' : 'Nb ${b.noBallRuns}');
      }
      if (b.byeRuns > 0) parts.add('B${b.byeRuns}');
      if (b.legByeRuns > 0) parts.add('LB${b.legByeRuns}');
      if (b.batterRuns > 0) parts.add('${b.batterRuns}');
      if (parts.isEmpty) parts.add('.');
      if (b.hasWicket) parts.add('W (${b.wicket!.type.name})');
      return parts.join(' ');
    }

    pw.Widget ballTable(List<BallEvent> events) {
      return pw.TableHelper.fromTextArray(
        headers: const ['Ball', 'Bowler', 'Batter', 'Result'],
        data: events
            .map(
              (b) => [
                '${b.overNumber}.${b.legalBallNumber}',
                playerName(b.bowlerId),
                playerName(b.strikerId),
                eventResult(b),
              ],
            )
            .toList(),
        cellStyle: const pw.TextStyle(fontSize: 7),
        headerStyle: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      );
    }

    pw.Widget ballByBallSection(List<BallEvent> events) {
      final byOver = <int, List<BallEvent>>{};
      for (final event in events) {
        byOver.putIfAbsent(event.overNumber, () => []).add(event);
      }
      final overNumbers = byOver.keys.toList()..sort();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Ball by Ball',
            style: pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          for (final overNumber in overNumbers) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: .5)),
              child: pw.Text(
                'Over $overNumber - ${playerName(byOver[overNumber]!.first.bowlerId)}',
                style: pw.TextStyle(font: boldFont, fontSize: 8),
              ),
            ),
            ballTable(byOver[overNumber]!),
            pw.SizedBox(height: 7),
          ],
        ],
      );
    }

    final baseFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('CRICKET SCORER', style: pw.TextStyle(fontSize: 9)),
            pw.Text('Full Match Scorecard', style: pw.TextStyle(fontSize: 9)),
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
          pw.Text(
            match.name,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          if (tournament != null) pw.Text('Tournament: ${tournament.name}'),
          pw.Text('Date: ${_date(match.date)}'),
          if (match.venue != null && match.venue!.trim().isNotEmpty)
            pw.Text('Venue: ${match.venue}'),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  resultText(),
                  style: pw.TextStyle(font: boldFont, fontSize: 15),
                ),
                if (match.tossWinnerTeamId != null && match.tossDecision != null)
                  pw.Text(
                    'Toss: ${teamName(match.tossWinnerTeamId!)} elected '
                    '${_tossLabel(match.tossDecision!)}',
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Teams',
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
          ...matchTeams.map((mt) {
            final teamPlayers = matchPlayers
                .where((p) => p.teamId == mt.teamId)
                .toList()
              ..sort(
                (a, b) => (a.battingOrder ?? 999).compareTo(b.battingOrder ?? 999),
              );
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  teamName(mt.teamId),
                  style: pw.TextStyle(font: boldFont),
                ),
                ...teamPlayers.map((p) => pw.Text('- ${playerName(p.playerId)}')),
                pw.SizedBox(height: 5),
              ],
            );
          }),
          ...List.generate(innings.length, (index) {
            final inning = innings[index];
            final state = inningsStates[index];
            final events = inningsEvents[inning.id] ?? const <BallEvent>[];
            final team = teamName(inning.battingTeamId);
            final batters = state.batters.values.toList()
              ..sort((a, b) => b.runs.compareTo(a.runs));
            final bowlers = state.bowlers.values.toList()
              ..sort((a, b) => b.legalBalls.compareTo(a.legalBalls));
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 16),
                pw.Text(
                  'Innings ${inning.inningsNumber} - $team',
                  style: pw.TextStyle(font: boldFont, fontSize: 15),
                ),
                pw.Text(
                  'Score: ${state.score}/${state.wickets}  Overs: ${state.completedOvers}',
                ),
                pw.SizedBox(height: 7),
                pw.Text('Batting', style: pw.TextStyle(font: boldFont)),
                pw.TableHelper.fromTextArray(
                  headers: const ['Batter', 'R', 'B', '4s', '6s', 'Status'],
                  data: batters
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
                  cellStyle: pw.TextStyle(font: baseFont, fontSize: 8),
                  headerStyle: pw.TextStyle(font: boldFont, fontSize: 8),
                ),
                pw.SizedBox(height: 7),
                pw.Text(
                  'Extras: ${state.wides} Wd, ${state.noBalls} Nb, '
                  '${state.byes} B, ${state.legByes} LB',
                ),
                pw.SizedBox(height: 7),
                pw.Text('Bowling', style: pw.TextStyle(font: boldFont)),
                pw.TableHelper.fromTextArray(
                  headers: const ['Bowler', 'Overs', 'Runs', 'Wkts'],
                  data: bowlers
                      .map(
                        (b) => [
                          playerName(b.playerId),
                          _overs(b.legalBalls),
                          '${b.runsConceded}',
                          '${b.wickets}',
                        ],
                      )
                      .toList(),
                  cellStyle: pw.TextStyle(font: baseFont, fontSize: 8),
                  headerStyle: pw.TextStyle(font: boldFont, fontSize: 8),
                ),
                pw.SizedBox(height: 7),
                ballByBallSection(events),
              ],
            );
          }),
        ],
      ),
    );
    return doc.save();
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _overs(int legalBalls) => '${legalBalls ~/ 6}.${legalBalls % 6}';

  String _tossLabel(TossDecision decision) => switch (decision) {
        TossDecision.bat => 'Bat',
        TossDecision.bowl => 'Bowl',
      };
}
