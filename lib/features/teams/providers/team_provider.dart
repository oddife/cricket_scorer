import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/teams/models/team.dart';

final teamProvider = AsyncNotifierProvider<TeamNotifier, List<Team>>(
  TeamNotifier.new,
);

class TeamNotifier extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() {
    return ref.watch(teamRepositoryProvider).getAll();
  }

  Future<Team?> add({
    required String name,
    required String shortName,
    String? logoPath,
  }) async {
    final trimmedName = name.trim();
    final trimmedShortName = shortName.trim();
    if (trimmedName.isEmpty || trimmedShortName.isEmpty) return null;

    final team = Team(
      id: 0,
      name: trimmedName,
      shortName: trimmedShortName,
      logoPath: logoPath,
    );
    final createdTeam = await ref.read(teamRepositoryProvider).create(team);
    ref.invalidateSelf();
    await future;
    return createdTeam;
  }

  Future<void> updateTeam(Team team) async {
    await ref.read(teamRepositoryProvider).update(team);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deactivate(int teamId) async {
    await ref.read(teamRepositoryProvider).deactivate(teamId);
    ref.invalidateSelf();
    await future;
  }
}
