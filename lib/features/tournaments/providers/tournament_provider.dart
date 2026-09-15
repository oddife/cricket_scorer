import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/tournaments/enums/tournament_type.dart';
import '../../../domain/tournaments/models/tournament.dart';

final tournamentProvider = AsyncNotifierProvider<TournamentNotifier, List<Tournament>>(
  TournamentNotifier.new,
);

class TournamentNotifier extends AsyncNotifier<List<Tournament>> {
  @override
  Future<List<Tournament>> build() {
    return ref.watch(tournamentRepositoryProvider).getAll();
  }

  Future<Tournament?> add({
    required String name,
    required TournamentType type,
    String? logoPath,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    final tournament = Tournament(
      id: 0,
      name: trimmedName,
      type: type,
      logoPath: logoPath,
      startDate: startDate,
      endDate: endDate,
    );
    final created = await ref.read(tournamentRepositoryProvider).create(tournament);
    ref.invalidateSelf();
    await future;
    return created;
  }

  Future<void> updateTournament(Tournament tournament) async {
    await ref.read(tournamentRepositoryProvider).update(tournament);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deactivate(int tournamentId) async {
    await ref.read(tournamentRepositoryProvider).deactivate(tournamentId);
    ref.invalidateSelf();
    await future;
  }
}
