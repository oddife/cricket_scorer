import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/application/matches/man_of_match_suggestion_service.dart';
import 'package:cricket_scorer/domain/innings/enums/innings_status.dart';
import 'package:cricket_scorer/domain/innings/models/innings.dart';
import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/enums/wicket_type.dart';
import 'package:cricket_scorer/domain/scoring/models/ball_event.dart';
import 'package:cricket_scorer/domain/scoring/models/wicket.dart';

Innings _innings(int id, int number) => Innings(
      id: id,
      matchId: 1,
      inningsNumber: number,
      battingTeamId: number.isOdd ? 1 : 2,
      bowlingTeamId: number.isOdd ? 2 : 1,
      openingStrikerId: 1,
      openingNonStrikerId: 2,
      openingBowlerId: 3,
      oversPerInnings: 20,
      ballsPerOver: 6,
      twoBowlerMode: false,
      status: InningsStatus.ended,
    );

BallEvent _ball({
  required int id,
  required int inningsId,
  required int strikerId,
  required int bowlerId,
  int batterRuns = 0,
  int totalRuns = 0,
  Wicket? wicket,
}) =>
    BallEvent(
      id: id,
      inningsId: inningsId,
      sequenceNumber: id,
      overNumber: 1,
      legalBallNumber: id,
      bowlerId: bowlerId,
      strikerId: strikerId,
      nonStrikerId: 99,
      deliveryType: DeliveryType.normal,
      isLegalBall: true,
      batterRuns: batterRuns,
      byeRuns: 0,
      legByeRuns: 0,
      wideRuns: 0,
      noBallRuns: 0,
      totalRuns: totalRuns,
      wicket: wicket,
      timestamp: DateTime(2026, 1, 1),
    );

void main() {
  test('suggestion aggregates across innings and weighs wickets as impact', () {
    final innings = [_innings(1, 1), _innings(2, 2)];
    final balls = <int, List<BallEvent>>{
      1: [
        for (var i = 1; i <= 5; i++)
          _ball(
            id: i,
            inningsId: 1,
            strikerId: 10,
            bowlerId: 21,
            batterRuns: 5,
            totalRuns: 5,
          ),
        _ball(
          id: 6,
          inningsId: 1,
          strikerId: 30,
          bowlerId: 20,
          wicket: const Wicket(
            type: WicketType.bowled,
            dismissedPlayerId: 30,
            creditedToBowler: true,
          ),
        ),
      ],
      2: [
        _ball(
          id: 7,
          inningsId: 2,
          strikerId: 31,
          bowlerId: 20,
          wicket: const Wicket(
            type: WicketType.caught,
            dismissedPlayerId: 31,
            fielderId: 40,
            creditedToBowler: true,
          ),
        ),
      ],
    };

    final suggestion = const ManOfMatchSuggestionService().suggest(
      innings: innings,
      ballsByInnings: balls,
    );

    expect(suggestion, isNotNull);
    expect(suggestion!.playerId, 20);
    expect(suggestion.runs, 0);
    expect(suggestion.wickets, 2);
    expect(suggestion.runsConceded, 0);
  });

  test('returns null when there is no recorded player contribution', () {
    final suggestion = const ManOfMatchSuggestionService().suggest(
      innings: [_innings(1, 1)],
      ballsByInnings: const {},
    );

    expect(suggestion, isNull);
  });
}
