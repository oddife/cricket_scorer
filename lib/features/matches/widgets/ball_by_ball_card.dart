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
    final titleOver = '${currentOverNumber + 1}.${overBalls.where((b) => b.isLegalBall).length}';

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
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final ball in overBalls)
                    Tooltip(
                      message: ball.hasWicket
                          ? 'Wicket'
                          : '${ball.deliveryType.name} • ${ball.totalRuns} run${ball.totalRuns == 1 ? '' : 's'}',
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: _background(context, ball),
                        child: Text(
                          _label(ball),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
