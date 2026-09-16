import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/players/models/player.dart';
import '../../players/providers/player_provider.dart';
import '../../players/widgets/add_player_dialog.dart';
import '../providers/team_player_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/team_squad_list.dart';
import '../widgets/team_squad_table.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  const TeamDetailScreen({required this.teamId, super.key});

  final int teamId;

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer(List<Player> members) async {
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
          if (created != null && mounted) {
            await _addPlayerToTeam(created);
          }
        },
      ),
    );

    if (selected != null && mounted) {
      await _addPlayerToTeam(selected);
    }
  }

  Future<void> _addPlayerToTeam(Player player) async {
    try {
      await ref.read(teamPlayerRepositoryProvider).addPlayerToTeam(
            teamId: widget.teamId,
            playerId: player.id,
          );
      ref.invalidate(teamPlayersProvider(widget.teamId));
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _removePlayer(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Player?'),
        content: Text(
          'Remove ${player.displayName} from this team? The global player will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref
        .read(teamPlayerRepositoryProvider)
        .removePlayerFromTeam(widget.teamId, player.id);
    ref.invalidate(teamPlayersProvider(widget.teamId));
  }

  List<Player> _filterPlayers(List<Player> players) {
    final query = _search.toLowerCase();
    if (query.isEmpty) return players;
    return players.where((player) {
      return player.name.toLowerCase().contains(query) ||
          player.displayName.toLowerCase().contains(query) ||
          (player.jerseyNumber?.toString().contains(query) ?? false);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final team = ref
        .watch(teamProvider)
        .value
        ?.where((item) => item.id == widget.teamId)
        .firstOrNull;
    final members = ref.watch(teamPlayersProvider(widget.teamId));
    final wide = MediaQuery.sizeOf(context).width >= 800;

    if (team == null) {
      return const Scaffold(body: Center(child: Text('Team not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        actions: [
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => _addPlayer(members.value ?? const []),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add Player'),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Add player',
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () => _addPlayer(members.value ?? const []),
            ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addPlayer(members.value ?? const []),
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

          final filtered = _filterPlayers(items);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value.trim()),
                  decoration: InputDecoration(
                    labelText: 'Search team squad',
                    hintText: 'Name or jersey number',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching players.'))
                    : wide
                        ? TeamSquadTable(
                            players: filtered,
                            onRemove: _removePlayer,
                          )
                        : TeamSquadList(
                            players: filtered,
                            onRemove: _removePlayer,
                          ),
              ),
            ],
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
          (player.jerseyNumber?.toString().contains(query) ?? false);
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
