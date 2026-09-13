import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/players/models/player.dart';

final playerProvider = AsyncNotifierProvider<PlayerNotifier, List<Player>>(
  PlayerNotifier.new,
);

class PlayerNotifier extends AsyncNotifier<List<Player>> {
  @override
  Future<List<Player>> build() {
    return ref.watch(playerRepositoryProvider).getAll();
  }

  Future<void> add({required String name, required String displayName}) async {
    final trimmedName = name.trim();
    final trimmedDisplayName = displayName.trim();
    if (trimmedName.isEmpty || trimmedDisplayName.isEmpty) return;

    final repository = ref.read(playerRepositoryProvider);
    final player = Player(
      id: 0,
      name: trimmedName,
      displayName: trimmedDisplayName,
    );
    await repository.create(player);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deactivate(int playerId) async {
    await ref.read(playerRepositoryProvider).deactivate(playerId);
    ref.invalidateSelf();
    await future;
  }
}
