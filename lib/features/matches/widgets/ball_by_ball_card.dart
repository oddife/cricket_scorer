
import 'package:flutter/material.dart';

import '../../../domain/scoring/enums/delivery_type.dart';
import '../../../domain/scoring/models/ball_event.dart';
import 'bowler_colour_coding.dart';

class BallByBallCard extends StatefulWidget {
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

  @override
  State<BallByBallCard> createState() => _BallByBallCardState();
}

class _BallByBallCardState extends State<BallByBallCard> {
  final ScrollController _scrollController = ScrollController();

  List<BallEvent> get balls => widget.balls;
  int get currentOverNumber => widget.currentOverNumber;
  int get ballsPerOver => widget.ballsPerOver;
  int? get matchId => widget.matchId;
  bool get showBowlerColours => widget.showBowlerColours;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  @override
  void didUpdateWidget(covariant BallByBallCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balls.length != widget.balls.length ||
        oldWidget.currentOverNumber != widget.currentOverNumber) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    }
  }

  void _scrollToLatest() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    _scrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
    // Keep every over in the strip. Each over owns a fixed-width group, so
    // deliveries don't jump around as the over fills. A wider gap separates
    // overs, and the strip scrolls to the latest ball as scoring continues.
    final ballsByOver = <int, List<BallEvent>>{};
    for (final ball in balls) {
      ballsByOver.putIfAbsent(ball.overNumber, () => <BallEvent>[]).add(ball);
    }
    final currentOverBalls =
        ballsByOver[currentOverNumber] ?? const <BallEvent>[];
    final legalBallCount =
        currentOverBalls.where((ball) => ball.isLegalBall).length;
    final titleOver = '$currentOverNumber.$legalBallCount';

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
                    'Ball by Ball',
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
            if (balls.isEmpty)
              Text(
                'No deliveries yet',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final viewportWidth = constraints.maxWidth;
                  final overs = ballsByOver.entries.toList(growable: false);

                  return SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var overIndex = 0;
                            overIndex < overs.length;
                            overIndex++) ...[
                          if (overIndex > 0) const SizedBox(width: 24),
                          Builder(
                            builder: (context) {
                              final overBalls = overs[overIndex].value;
                              final slotCount = overBalls.length > ballsPerOver
                                  ? overBalls.length
                                  : ballsPerOver;
                              final naturalWidth = overBalls.length * 36.0;
                              // Extras can make an over wider than the normal
                              // viewport; reserve enough room for every ball.
                              final groupWidth = naturalWidth > viewportWidth
                                  ? naturalWidth
                                  : viewportWidth;
                              final slotWidth = groupWidth / slotCount;
                              final radius = (slotWidth / 2 - 2)
                                  .clamp(10.0, 18.0)
                                  .toDouble();

                              return SizedBox(
                                width: groupWidth,
                                child: Row(
                                  children: [
                                    for (var index = 0;
                                        index < slotCount;
                                        index++)
                                      Expanded(
                                        child: Center(
                                          child: index < overBalls.length
                                              ? Tooltip(
                                                  message: _tooltip(
                                                    overBalls[index],
                                                  ),
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
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
}
