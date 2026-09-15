import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/team_provider.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/edit_team_dialog.dart';
import '../widgets/team_logo.dart';

class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTeamDialog(context, ref),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Add Team'),
      ),
      body: teams.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load teams: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No teams yet. Add your first team.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final team = items[index];
              return Card(
                child: ListTile(
                  leading: TeamLogo(teamName: team.name, logoPath: team.logoPath),
                  title: Text(team.name),
                  subtitle: Text(team.shortName),
                  onTap: () => context.push('/teams/${team.id}'),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Team management',
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await showEditTeamDialog(context, ref, team);
                      } else if (value == 'deactivate') {
                        await ref.read(teamProvider.notifier).deactivate(team.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit Team'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deactivate',
                        child: ListTile(
                          leading: Icon(Icons.archive_outlined),
                          title: Text('Deactivate Team'),
                        ),
                      ),
                    ],
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
