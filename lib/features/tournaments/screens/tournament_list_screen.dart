import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/tournament_provider.dart';
import '../widgets/edit_tournament_dialog.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_table.dart';

class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen> {
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
    final tournamentsAsync = ref.watch(tournamentProvider);
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: () => context.push('/tournaments/new'),
                icon: const Icon(Icons.add),
                label: const Text('New Tournament'),
              ),
            ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/tournaments/new'),
              icon: const Icon(Icons.add),
              label: const Text('New Tournament'),
            ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load tournaments: $error')),
        data: (tournaments) {
          final visible = tournaments.where((tournament) {
            if (!_showInactive && !tournament.isActive) return false;
            final query = _search.trim().toLowerCase();
            if (query.isEmpty) return true;
            return tournament.name.toLowerCase().contains(query) ||
                tournament.type.toString().split('.').last.toLowerCase().contains(query);
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  _TournamentFilters(
                    controller: _searchController,
                    showInactive: _showInactive,
                    onSearchChanged: (value) => setState(() => _search = value),
                    onShowInactiveChanged: (value) => setState(() => _showInactive = value),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? _EmptyTournaments(hasTournaments: tournaments.isNotEmpty)
                        : wide
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: TournamentTable(
                                  tournaments: visible,
                                  onOpen: (tournament) =>
                                      context.push('/tournaments/${tournament.id}'),
                                  onManage: (tournament) =>
                                      context.push('/tournaments/${tournament.id}/manage'),
                                  onEdit: (tournament) =>
                                      showEditTournamentDialog(context, ref, tournament),
                                  onDeactivate: _deactivate,
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                itemCount: visible.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final tournament = visible[index];
                                  return TournamentCard(
                                    tournament: tournament,
                                    onTap: () => context.push('/tournaments/${tournament.id}'),
                                    onManage: () => context.push(
                                      '/tournaments/${tournament.id}/manage',
                                    ),
                                    onEdit: () => showEditTournamentDialog(
                                      context,
                                      ref,
                                      tournament,
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deactivate(dynamic tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate tournament?'),
        content: Text('Deactivate “${tournament.name}”? It will be hidden from the active list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(tournamentProvider.notifier).deactivate(tournament.id);
  }
}

class _TournamentFilters extends StatelessWidget {
  const _TournamentFilters({
    required this.controller,
    required this.showInactive,
    required this.onSearchChanged,
    required this.onShowInactiveChanged,
  });

  final TextEditingController controller;
  final bool showInactive;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onShowInactiveChanged;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: wide
          ? Row(
              children: [
                Expanded(child: _searchField()),
                const SizedBox(width: 16),
                _inactiveFilter(),
              ],
            )
          : Column(
              children: [
                _searchField(),
                Align(alignment: Alignment.centerLeft, child: _inactiveFilter()),
              ],
            ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: controller,
      onChanged: onSearchChanged,
      decoration: const InputDecoration(
        labelText: 'Search tournaments',
        hintText: 'Name or type',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _inactiveFilter() {
    return FilterChip(
      label: const Text('Show inactive'),
      selected: showInactive,
      onSelected: onShowInactiveChanged,
    );
  }
}

class _EmptyTournaments extends StatelessWidget {
  const _EmptyTournaments({required this.hasTournaments});

  final bool hasTournaments;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              hasTournaments ? 'No matching tournaments' : 'No tournaments yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasTournaments
                  ? 'Try a different search or show inactive tournaments.'
                  : 'Create your first tournament to get started.',
              textAlign: TextAlign.center,
            ),
            if (!hasTournaments) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push('/tournaments/new'),
                icon: const Icon(Icons.add),
                label: const Text('Create Tournament'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
