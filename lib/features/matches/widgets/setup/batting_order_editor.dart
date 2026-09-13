import 'package:flutter/material.dart';

import '../../../../domain/players/models/player.dart';

class BattingOrderEditor extends StatelessWidget {
  const BattingOrderEditor({
    super.key,
    required this.players,
    required this.order,
    required this.onChanged,
  });

  final List<Player> players;
  final List<int> order;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final player in players) player.id: player};
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: order.length,
      onReorderItem: (oldIndex, newIndex) {
        final next = List<int>.from(order);
        final id = next.removeAt(oldIndex);
        next.insert(newIndex, id);
        onChanged(next);
      },
      itemBuilder: (context, index) {
        final player = byId[order[index]];
        return ListTile(
          key: ValueKey(order[index]),
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(player?.displayName ?? 'Player ${order[index]}'),
          subtitle: player?.jerseyNumber == null
              ? null
              : Text('#${player!.jerseyNumber}'),
          trailing: const Icon(Icons.drag_handle),
        );
      },
    );
  }
}
