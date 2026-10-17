
import 'package:flutter/material.dart';

import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/models/ball_event.dart';
import 'bowler_colour_coding.dart';

class BallByBallCard extends StatelessWidget {
  const BallByBallCard({
    super.key,
    required this.balls,
    required this.currentOverNumber,
    required this.ballsPerOver,
    this.matchId,
    this.showBowlerColours = false,
  });

  final List<BallEvent> balls;
  final int currentOverNumber;
  final int ballsPerOver;
  final int? matchId;
  final bool showBowlerColours;

  String _label(BallEvent ball) {
    if (ball.hasWicket) {
      final runs = ball.totalRuns;
      return runs > 0 ? '$runs + W' : 'W';
    }
    switch (ball.deliveryType) {
      case DeliveryType.wide:
        return ball.wideRuns <= 1 ? 'WD' : 'WD+${ball.wideRuns - 1}';
      case DeliveryType.noBall:
        final additional = ball.totalRuns - ball.noBallRuns;
        return additional > 0 ? 'NB+$additional' : 'NB';
      case DeliveryType.bye:
        return 'B${ball.byeRuns > 1 ? '+${ball.byeRuns}' : ''}';
      case DeliveryType.legBye:
        return 'LB${ball.legByeRuns > 1 ? '+${ball.legByeRuns}' : ''}';
      case DeliveryType.normal:
        return '${ball.batterRuns}';
    }
  }

  Color _background(BuildContext context, BallEvent ball) {
    final scheme = Theme.of(context).colorScheme;
    if (ball.hasWicket) return scheme.errorContainer;
    if (ball.isBoundary) return scheme.primaryContainer;
    if (!ball.isLegalBall) return scheme.tertiaryContainer;
    return scheme.surfaceContainerHighest;
  }

  Widget _ballAvatar(BuildContext context, BallEvent ball, double radius) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: _background(context, ball),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            _label(ball),
            maxLines: 1,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );

    if (!showBowlerColours || matchId == null || ball.bowlerId <= 0) {
      return avatar;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: BowlerColourCoding.colorForBowler(
          matchId: matchId!,
          playerId: ball.bowlerId,
        ),
        shape: BoxShape.circle,
      ),
      child: avatar,
    );
  }

  String _tooltip(BallEvent ball) => ball.hasWicket
      ? 'Wicket'
      : '${ball.deliveryType.name} • ${ball.totalRuns} run'
          '${ball.totalRuns == 1 ? '' : 's'}';

  @override
  Widget build(BuildContext context) {
    final overBalls = balls
        .where((ball) => ball.overNumber == currentOverNumber)
        .toList(growable: false);
    final titleOver =
        '$currentOverNumber.${overBalls.where((b) => b.isLegalBall).length}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'This Over',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$titleOver ov',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (overBalls.isEmpty)
              Text(
                'No deliveries yet',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else if (overBalls.length <= ballsPerOver)
              SizedBox(
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Allocate a fixed slot for every ball in the over.
                    // If slots were divided by the number of deliveries so far,
                    // the first ball would jump as each new delivery arrived.
                    final slotWidth = constraints.maxWidth / ballsPerOver;
                    final radius =
                        (slotWidth / 2 - 2).clamp(10.0, 18.0).toDouble();
                    return Row(
                      children: [
                        for (var index = 0; index < ballsPerOver; index++)
                          Expanded(
                            child: Center(
                              child: index < overBalls.length
                                  ? Tooltip(
                                      message: _tooltip(overBalls[index]),
                                      child: _ballAvatar(
                                        context,
                                        overBalls[index],
                                        radius,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < overBalls.length; index++) ...[
                      if (index > 0) const SizedBox(width: 6),
                      Tooltip(
                        message: _tooltip(overBalls[index]),
                        child: _ballAvatar(context, overBalls[index], 16),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
