import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/player.dart';
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _DesktopSummary(
                      total: items.length,
                      active: activeCount,
                      inactive: inactiveCount,
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
                        label: Text('Inactive${inactiveCount == 0 ? '' : ' ($inactiveCount)'}'),
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
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: DataTable(
              columnSpacing: 28,
              headingRowHeight: 52,
              dataRowMinHeight: 64,
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
                        width: 300,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: PlayerAvatar(
                            displayName: player.displayName,
                            photoPath: player.photoPath,
                          ),
                          title: Text(
                            player.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            player.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => context.push('/players/${player.id}'),
                        ),
                      ),
                    ),
                    DataCell(Text(player.jerseyNumber?.toString() ?? '—')),
                    DataCell(Text(player.battingStyle.label)),
                    DataCell(Text(player.bowlingStyle.label)),
                    DataCell(_StatusChip(active: player.isActive)),
                    DataCell(_buildActions(context, player)),
                  ],
                );
              }).toList(growable: false),
            ),
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
        } else if (value == 'toggle' && player.isActive) {
          await ref.read(playerProvider.notifier).deactivate(player.id);
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
      ],
    );
  }
}

class _DesktopSummary extends StatelessWidget {
  const _DesktopSummary({
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Total Players', value: total, icon: Icons.groups_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(label: 'Active', value: active, icon: Icons.check_circle_outline)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(label: 'Inactive', value: inactive, icon: Icons.archive_outlined)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text('$value', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(active ? Icons.check : Icons.archive_outlined, size: 16),
      label: Text(active ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
    );
  }
}
