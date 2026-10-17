import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/domain/scoring/enums/delivery_type.dart';
import 'package:cricket_scorer/domain/scoring/models/ball_event.dart';
import 'package:cricket_scorer/features/matches/widgets/ball_by_ball_card.dart';

BallEvent _ball(int id) => BallEvent(
      id: id,
      inningsId: 1,
      sequenceNumber: id,
      overNumber: 1,
      legalBallNumber: id,
      bowlerId: 20,
      strikerId: 10,
      nonStrikerId: 11,
      deliveryType: DeliveryType.normal,
      isLegalBall: true,
      batterRuns: 0,
      byeRuns: 0,
      legByeRuns: 0,
      wideRuns: 0,
      noBallRuns: 0,
      totalRuns: 0,
      wicket: null,
      timestamp: DateTime(2026, 10, 17),
    );

void main() {
  testWidgets('six balls in the current over stay on a single row', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: BallByBallCard(
              balls: List.generate(6, (index) => _ball(index + 1)),
              currentOverNumber: 1,
              ballsPerOver: 6,
            ),
          ),
        ),
      ),
    );

    final avatars = find.byType(CircleAvatar);
    expect(avatars, findsNWidgets(6));

    final yPositions = <double>{
      for (var index = 0; index < 6; index++)
        tester.getTopLeft(avatars.at(index)).dy,
    };
    expect(yPositions, hasLength(1));
  });

  testWidgets('two-bowler mode adds thin rings without changing the ball row', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: BallByBallCard(
              balls: List.generate(6, (index) => _ball(index + 1)),
              currentOverNumber: 1,
              ballsPerOver: 6,
              matchId: 7,
              showBowlerColours: true,
            ),
          ),
        ),
      ),
    );

    final avatars = find.byType(CircleAvatar);
    expect(avatars, findsNWidgets(6));

    final colouredRings = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.padding == const EdgeInsets.all(2) &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
    );
    expect(colouredRings, findsNWidgets(6));
    expect(
      tester.getTopLeft(avatars.first).dy,
      tester.getTopLeft(avatars.last).dy,
    );
  });
  testWidgets('balls stay in fixed left-to-right slots as deliveries arrive', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    Widget buildCard(int ballCount) => MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: BallByBallCard(
                balls: List.generate(ballCount, (index) => _ball(index + 1)),
                currentOverNumber: 1,
                ballsPerOver: 6,
              ),
            ),
          ),
        );

    await tester.pumpWidget(buildCard(1));
    final firstBallX = tester.getCenter(find.byType(CircleAvatar).first).dx;

    await tester.pumpWidget(buildCard(2));
    await tester.pumpAndSettle();

    final avatars = find.byType(CircleAvatar);
    expect(avatars, findsNWidgets(2));
    expect(
      tester.getCenter(avatars.first).dx,
      closeTo(firstBallX, 0.1),
    );
    expect(
      tester.getCenter(avatars.last).dx,
      greaterThan(firstBallX),
    );
  });

}
