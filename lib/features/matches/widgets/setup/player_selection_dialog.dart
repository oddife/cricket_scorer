import 'package:flutter/material.dart';

import '../../../../domain/players/enums/batting_style.dart';
import '../../../../domain/players/enums/bowling_style.dart';
import '../../../../domain/players/models/player.dart';

class PlayerSelectionDialog extends StatefulWidget {
  const PlayerSelectionDialog({
    super.key,
    required this.title,
    required this.players,
    required this.initialSelection,
    required this.requiredCount,
  });

  final String title;
  final List<Player> players;
  final List<int> initialSelection;
  final int requiredCount;

  @override
  State<PlayerSelectionDialog> createState() => _PlayerSelectionDialogState();
}

class _PlayerSelectionDialogState extends State<PlayerSelectionDialog> {
  late final Set<int> _selected = widget.initialSelection.toSet();

  @override
  Widget build(BuildContext context) {
    final canFinish = _selected.length >= widget.requiredCount;

    return AlertDialog(
      title: Text('${widget.title} (${_selected.length} selected)'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select the players available for this match. Select at least '
              '${widget.requiredCount}; batting order is set separately.',
            ),
            const SizedBox(height: 12),
            Flexible(
              child: widget.players.isEmpty
                  ? const Center(child: Text('No players available.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.players.length,
                      itemBuilder: (context, index) {
                        final player = widget.players[index];
                        final selected = _selected.contains(player.id);
                        return CheckboxListTile(
                          value: selected,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(player.displayName),
                          subtitle: Text(_details(player)),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selected.add(player.id);
                              } else {
                                _selected.remove(player.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canFinish
              ? () => Navigator.pop(context, _selected.toList())
              : null,
          child: const Text('Done'),
        ),
      ],
    );
  }

  String _details(Player player) {
    final jersey = player.jerseyNumber == null ? '' : '#${player.jerseyNumber} · ';
    return '$jersey${player.battingStyle.label} bat · ${player.bowlingStyle.label} arm';
  }
}
