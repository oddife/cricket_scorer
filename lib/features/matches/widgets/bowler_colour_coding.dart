import 'package:flutter/material.dart';

/// Deterministic colour coding shared by Android and Flutter Web.
///
/// A player's shared sync identity is preferred to any installation-local ID.
class BowlerColourCoding {
  const BowlerColourCoding._();

  /// Derives a colour from a shared player identity, never a device-local ID.
  ///
  /// The explicit FNV-1a hash keeps the result stable across Dart runtimes,
  /// Android and Flutter Web (unlike [String.hashCode]).
  static Color colorForBowler({required String playerIdentity}) {
    // Keep intermediates below JavaScript's exact-integer limit so Web and
    // native Dart calculate the same result for every shared identity.
    var hash = 17;
    for (final codeUnit in playerIdentity.codeUnits) {
      hash = (hash * 31 + codeUnit) % 2147483647;
    }
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.72, 0.78).toColor();
  }
}

/// Adds a thin bowler-colour outline without changing the text's style.
class BowlerNameOutline extends StatelessWidget {
  const BowlerNameOutline({
    super.key,
    required this.enabled,
    required this.playerIdentity,
    required this.child,
  });

  final bool enabled;
  final String playerIdentity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || playerIdentity.isEmpty) return child;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(
          color: BowlerColourCoding.colorForBowler(
            playerIdentity: playerIdentity,
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
    required this.bowlerIds,
    required this.name,
    required this.playerIdentity,
  });

  final bool enabled;
  final List<int> bowlerIds;
  final String Function(int) name;
  final String Function(int) playerIdentity;

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
                    playerIdentity: playerIdentity(id),
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
