import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/players/enums/batting_style.dart';
import '../../../domain/players/enums/bowling_style.dart';
import '../../../domain/players/models/player.dart';

/// Global player catalog used by match setup and player management.
final playerProvider = AsyncNotifierProvider<PlayerNotifier, List<Player>>(
  PlayerNotifier.new,
);

class PlayerNotifier extends AsyncNotifier<List<Player>> {
  @override
  Future<List<Player>> build() {
    return ref.watch(playerRepositoryProvider).getAll();
  }

  Future<Player?> add({
    required String name,
    required String displayName,
    int? jerseyNumber,
    BattingStyle battingStyle = BattingStyle.right,
    BowlingStyle bowlingStyle = BowlingStyle.right,
  }) async {
    final trimmedName = name.trim();
    final trimmedDisplayName = displayName.trim();
    if (trimmedName.isEmpty || trimmedDisplayName.isEmpty) return null;

    final repository = ref.read(playerRepositoryProvider);
    final player = Player(
      id: 0,
      name: trimmedName,
      displayName: trimmedDisplayName,
      jerseyNumber: jerseyNumber,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
    );
    final createdPlayer = await repository.create(player);
    ref.invalidateSelf();
    await future;
    return createdPlayer;
  }

  Future<void> deactivate(int playerId) async {
    await ref.read(playerRepositoryProvider).deactivate(playerId);
    ref.invalidateSelf();
    await future;
  }
}
