import 'package:flutter/material.dart';

import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/models/ball_event.dart';

class BallByBallCard extends StatelessWidget {
  const BallByBallCard({
    super.key,
    required this.balls,
    required this.currentOverNumber,
    required this.ballsPerOver,
  });

  final List<BallEvent> balls;
  final int currentOverNumber;
  final int ballsPerOver;

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

  @override
  Widget build(BuildContext context) {
    final overBalls = balls
        .where((ball) => ball.overNumber == currentOverNumber)
        .toList(growable: false);
    final titleOver = '$currentOverNumber.${overBalls.where((b) => b.isLegalBall).length}';

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
              // Fit a normal over into exactly one row. Expanded slots prevent
              // six full-size avatars from wrapping on narrow phone layouts.
              SizedBox(
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slotWidth =
                        constraints.maxWidth / overBalls.length;
                    final radius =
                        (slotWidth / 2 - 2).clamp(10.0, 18.0).toDouble();
                    return Row(
                      children: [
                        for (final ball in overBalls)
                          Expanded(
                            child: Center(
                              child: Tooltip(
                                message: ball.hasWicket
                                    ? 'Wicket'
                                    : '${ball.deliveryType.name} • '
                                        '${ball.totalRuns} run'
                                        '${ball.totalRuns == 1 ? '' : 's'}',
                                child: CircleAvatar(
                                  radius: radius,
                                  backgroundColor: _background(context, ball),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      child: Text(
                                        _label(ball),
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              )
            else
              // Extras can mean more than six recorded deliveries in one over.
              // Keep those visible on one line with horizontal scrolling.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < overBalls.length; index++) ...[
                      if (index > 0) const SizedBox(width: 6),
                      Tooltip(
                        message: overBalls[index].hasWicket
                            ? 'Wicket'
                            : '${overBalls[index].deliveryType.name} • '
                                '${overBalls[index].totalRuns} run'
                                '${overBalls[index].totalRuns == 1 ? '' : 's'}',
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: _background(context, overBalls[index]),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                _label(overBalls[index]),
                                maxLines: 1,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
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
