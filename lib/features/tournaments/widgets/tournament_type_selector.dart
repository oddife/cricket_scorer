import 'package:flutter/material.dart';

import '../../../domain/tournaments/enums/tournament_type.dart';

class TournamentTypeSelector extends StatelessWidget {
  const TournamentTypeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final TournamentType value;
  final ValueChanged<TournamentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TournamentType>(
      segments: TournamentType.values
          .map(
            (type) => ButtonSegment<TournamentType>(
              value: type,
              label: Text(type.label),
            ),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}