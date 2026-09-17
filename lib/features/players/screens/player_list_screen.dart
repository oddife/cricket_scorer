import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/management/permanent_delete_service.dart';
import '../../../domain/players/models/player.dart';
import '../providers/player_provider.dart';
import '../widgets/add_player_dialog.dart';
import '../widgets/edit_player_dialog.dart';
import '../widgets/player_avatar.dart';

class PlayerListScreen extends ConsumerStatefulWidget {
  const PlayerListScreen({super.key});

  @override
  ConsumerState<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends ConsumerState<PlayerListScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deletePlayer(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete player permanently?'),
        content: Text(
          'Permanently delete “${player.displayName}” from the global player '
          'database and all team memberships?\n\nThis action cannot be undone. '
          'Players referenced by match history cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(permanentDeleteServiceProvider).deletePlayer(player.id);
      ref.invalidate(playerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player permanently deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete player: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        actions: [
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: () => showAddPlayerDialog(context, ref),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Player'),
              ),
            ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddPlayerDialog(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add Player'),
            ),
      body: players.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load players: $error')),
        data: (items) {
          final activeCount = items.where((player) => player.isActive).length;
          final inactiveCount = items.length - activeCount;
          final filtered = items.where((player) {
            if (!_showInactive && !player.isActive) return false;
            if (_search.isEmpty) return true;
            final query = _search.toLowerCase();
            return player.name.toLowerCase().contains(query) ||
                player.displayName.toLowerCase().contains(query) ||
                (player.jerseyNumber?.toString() == query);
          }).toList(growable: false);

          return Column(
            children: [
              if (wide)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ManagementSummaryCard(
                            label: 'Total Players',
                            value: items.length.toString(),
                            icon: Icons.groups_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ManagementSummaryCard(
                            label: 'Active',
                            value: activeCount.toString(),
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ManagementSummaryCard(
                            label: 'Inactive',
                            value: inactiveCount.toString(),
                            icon: Icons.person_off_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 16, wide ? 24 : 16, 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _search = value.trim()),
                          decoration: InputDecoration(
                            labelText: 'Search players',
                            hintText: 'Name, display name or jersey number',
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
                      const SizedBox(width: 12),
                      FilterChip(
                        label: Text('Inactive ($inactiveCount)'),
                        selected: _showInactive,
                        onSelected: (value) => setState(() => _showInactive = value),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _search.isEmpty
                              ? 'No players yet. Add your first global player.'
                              : 'No players match your search.',
                        ),
                      )
                    : wide
                        ? _buildDesktopTable(context, filtered)
                        : _buildMobileList(context, filtered),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<Player> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      horizontalMargin: 24,
                      columnSpacing: 36,
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      headingRowHeight: 56,
                      columns: const [
                        DataColumn(label: Text('Player')),
                        DataColumn(label: Text('Jersey')),
                        DataColumn(label: Text('Batting')),
                        DataColumn(label: Text('Bowling')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: items.map((player) {
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 320,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: PlayerAvatar(
                                    displayName: player.displayName,
                                    photoPath: player.photoPath,
                                  ),
                                  title: Text(player.displayName),
                                  onTap: () => context.push('/players/${player.id}'),
                                ),
                              ),
                            ),
                            DataCell(Text(player.jerseyNumber?.toString() ?? '—')),
                            DataCell(Text(player.battingStyle.label)),
                            DataCell(Text(player.bowlingStyle.label)),
                            DataCell(_StatusChip(isActive: player.isActive)),
                            DataCell(_buildActions(context, player)),
                          ],
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<Player> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = items[index];
        final jersey = player.jerseyNumber == null ? '' : ' • #${player.jerseyNumber}';
        return Card(
          child: ListTile(
            leading: PlayerAvatar(
              displayName: player.displayName,
              photoPath: player.photoPath,
            ),
            title: Text(player.displayName),
            subtitle: Text(
              '${player.name}$jersey\n${player.battingStyle.label} • ${player.bowlingStyle.label}',
            ),
            isThreeLine: true,
            onTap: () => context.push('/players/${player.id}'),
            trailing: _buildActions(context, player),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, Player player) {
    return PopupMenuButton<String>(
      tooltip: 'Player management',
      onSelected: (value) async {
        if (value == 'edit') {
          await showEditPlayerDialog(context, ref, player);
        } else if (value == 'toggle') {
          if (player.isActive) {
            await ref.read(playerProvider.notifier).deactivate(player.id);
          }
        } else if (value == 'delete') {
          await _deletePlayer(player);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit Player'),
          ),
        ),
        if (player.isActive)
          const PopupMenuItem(
            value: 'toggle',
            child: ListTile(
              leading: Icon(Icons.archive_outlined),
              title: Text('Deactivate Player'),
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Delete Permanently'),
          ),
        ),
      ],
    );
  }
}

class _ManagementSummaryCard extends StatelessWidget {
  const _ManagementSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isActive ? 'Active' : 'Inactive'),
      avatar: Icon(
        isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
        size: 18,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
