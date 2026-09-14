import 'package:flutter/material.dart';

import '../../../../domain/players/models/player.dart';

class BattingOrderSetupDialog extends StatefulWidget {
  const BattingOrderSetupDialog({
    super.key,
    required this.teamName,
    required this.players,
    required this.initialOrder,
    required this.requiredCount,
  });

  final String teamName;
  final List<Player> players;
  final List<int> initialOrder;
  final int requiredCount;

  @override
  State<BattingOrderSetupDialog> createState() =>
      _BattingOrderSetupDialogState();
}

class _BattingOrderSetupDialogState extends State<BattingOrderSetupDialog> {
  late final List<int> _order = _initialOrder();

  List<int> _initialOrder() {
    final available = {for (final player in widget.players) player.id};
    final seen = <int>{};
    return [
      for (final id in widget.initialOrder)
        if (available.contains(id) && seen.add(id)) id,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selected = _order.toSet();
    final canFinish = _order.length == widget.requiredCount;

    return AlertDialog(
      title: Text('${widget.teamName} batting order'),
      content: SizedBox(
        width: 620,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose exactly ${widget.requiredCount} players, then arrange their batting order.',
            ),
            const SizedBox(height: 12),
            Text(
              '${_order.length}/${widget.requiredCount} selected',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (final player in widget.players)
                    CheckboxListTile(
                      value: selected.contains(player.id),
                      title: Text(player.displayName),
                      subtitle: player.jerseyNumber == null
                          ? null
                          : Text('#${player.jerseyNumber}'),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (_order.length < widget.requiredCount) {
                              _order.add(player.id);
                            }
                          } else {
                            _order.remove(player.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            if (_order.isNotEmpty) ...[
              const Divider(),
              Text(
                'Batting order',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 150,
                child: ReorderableListView.builder(
                  itemCount: _order.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final id = _order.removeAt(oldIndex);
                      _order.insert(newIndex, id);
                    });
                  },
                  itemBuilder: (context, index) {
                    final player = widget.players.firstWhere(
                      (p) => p.id == _order[index],
                    );
                    return ListTile(
                      key: ValueKey(player.id),
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(player.displayName),
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                ),
              ),
            ],
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
              ? () => Navigator.pop(context, List<int>.unmodifiable(_order))
              : null,
          child: const Text('Save Batting Order'),
        ),
      ],
    );
  }
}
