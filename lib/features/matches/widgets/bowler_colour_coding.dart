import 'package:flutter/material.dart';

/// Deterministic, match-specific colour coding for two-bowler matches.
///
/// Colours derive from match/player IDs rather than list order, so a bowler's
/// colour does not change when the active pair or roster changes.
class BowlerColourCoding {
  const BowlerColourCoding._();

  static const int _modulus = 65521;

  static Color colorForBowler({
    required int matchId,
    required int playerId,
  }) {
    final seed = (playerId * 31 + matchId * 131) % _modulus;
    final mixed = (seed * 25173 + 13849) % _modulus;
    final hue = mixed * 360.0 / _modulus;
    return HSVColor.fromAHSV(1, hue, 0.72, 0.78).toColor();
  }
}

/// Adds a thin bowler-colour outline without changing the text's style.
class BowlerNameOutline extends StatelessWidget {
  const BowlerNameOutline({
    super.key,
    required this.enabled,
    required this.matchId,
    required this.bowlerId,
    required this.child,
  });

  final bool enabled;
  final int matchId;
  final int? bowlerId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || bowlerId == null || bowlerId! <= 0) return child;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(
          color: BowlerColourCoding.colorForBowler(
            matchId: matchId,
            playerId: bowlerId!,
          ),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: child,
    );
  }
}

/// Compact legend displayed below the active bowling-pair selector.
class BowlerColourLegend extends StatelessWidget {
  const BowlerColourLegend({
    super.key,
    required this.enabled,
    required this.matchId,
    required this.bowlerIds,
    required this.name,
  });

  final bool enabled;
  final int matchId;
  final List<int> bowlerIds;
  final String Function(int) name;

  @override
  Widget build(BuildContext context) {
    final ids = bowlerIds.toSet().toList(growable: false);
    if (!enabled || ids.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 5,
      children: [
        for (final id in ids)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: BowlerColourCoding.colorForBowler(
                    matchId: matchId,
                    playerId: id,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(name(id), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}
