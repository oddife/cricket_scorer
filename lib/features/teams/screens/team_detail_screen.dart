import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/players/models/player.dart';
import '../../players/providers/player_provider.dart';
import '../../players/widgets/add_player_dialog.dart';
import '../providers/team_player_provider.dart';
import '../providers/team_provider.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({required this.teamId, super.key});

  final int teamId;

  Future<void> _addPlayer(
    BuildContext context,
    WidgetRef ref,
    List<Player> members,
  ) async {
    final players = ref.read(playerProvider).value ?? const <Player>[];
    final memberIds = members.map((player) => player.id).toSet();
    final available = players
        .where((player) => player.isActive && !memberIds.contains(player.id))
        .toList(growable: false);

    final selected = await showDialog<Player>(
      context: context,
      builder: (dialogContext) => _GlobalPlayerPicker(
        players: available,
        onCreatePlayer: () async {
          Navigator.pop(dialogContext);
          final created = await showAddPlayerDialog(context, ref);
          if (created != null && context.mounted) {
            await _addPlayerToTeam(context, ref, created);
          }
        },
      ),
    );

    if (selected == null || !context.mounted) return;
    await _addPlayerToTeam(context, ref, selected);
  }

  Future<void> _addPlayerToTeam(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) async {
    try {
      await ref.read(teamPlayerRepositoryProvider).addPlayerToTeam(
            teamId: teamId,
            playerId: player.id,
          );
      ref.invalidate(teamPlayersProvider(teamId));
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref
        .watch(teamProvider)
        .value
        ?.where((item) => item.id == teamId)
        .firstOrNull;
    final members = ref.watch(teamPlayersProvider(teamId));

    if (team == null) {
      return const Scaffold(body: Center(child: Text('Team not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        actions: [
          IconButton(
            tooltip: 'Add player',
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () =>
                _addPlayer(context, ref, members.value ?? const []),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPlayer(context, ref, members.value ?? const []),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Player'),
      ),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load squad: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No players in this team yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final player = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      player.displayName.isEmpty
                          ? '?'
                          : player.displayName[0].toUpperCase(),
                    ),
                  ),
                  title: Text(player.displayName),
                  subtitle: Text(player.name),
                  trailing: IconButton(
                    tooltip: 'Remove from team',
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () async {
                      await ref
                          .read(teamPlayerRepositoryProvider)
                          .removePlayerFromTeam(teamId, player.id);
                      ref.invalidate(teamPlayersProvider(teamId));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GlobalPlayerPicker extends StatefulWidget {
  const _GlobalPlayerPicker({
    required this.players,
    required this.onCreatePlayer,
  });

  final List<Player> players;
  final Future<void> Function() onCreatePlayer;

  @override
  State<_GlobalPlayerPicker> createState() => _GlobalPlayerPickerState();
}

class _GlobalPlayerPickerState extends State<_GlobalPlayerPicker> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.toLowerCase();
    final players = widget.players.where((player) {
      return query.isEmpty ||
          player.name.toLowerCase().contains(query) ||
          player.displayName.toLowerCase().contains(query) ||
          player.jerseyNumber?.toString() == query;
    }).toList(growable: false);

    return AlertDialog(
      title: const Text('Add Player to Team'),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _search = value.trim()),
              decoration: const InputDecoration(
                labelText: 'Search global players',
                hintText: 'Name or jersey number',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: players.isEmpty
                  ? const Center(child: Text('No matching global players.'))
                  : ListView.separated(
                      itemCount: players.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              player.displayName.isEmpty
                                  ? '?'
                                  : player.displayName[0].toUpperCase(),
                            ),
                          ),
                          title: Text(player.displayName),
                          subtitle: Text(
                            '${player.name}${player.jerseyNumber == null ? '' : ' • #${player.jerseyNumber}'}',
                          ),
                          onTap: () => Navigator.pop(context, player),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: widget.onCreatePlayer,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Create New Global Player'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
