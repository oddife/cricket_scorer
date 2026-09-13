import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: Text('${widget.title} (${_selected.length}/${widget.requiredCount})'),
      content: SizedBox(
        width: 520,
        child: widget.players.isEmpty
            ? const Center(child: Text('No players in this team squad.'))
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
                    onChanged: selected || _selected.length < widget.requiredCount
                        ? (value) {
                            setState(() {
                              if (value == true) {
                                _selected.add(player.id);
                              } else {
                                _selected.remove(player.id);
                              }
                            });
                          }
                        : null,
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _selected.length == widget.requiredCount
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
