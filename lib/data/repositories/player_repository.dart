import '../../domain/players/models/player.dart';

abstract interface class PlayerRepository {
  Future<List<Player>> getAll();
  Future<List<Player>> getAllIncludingInactive();
  Future<Player> create(Player player);
  Future<void> update(Player player);
  Future<void> deactivate(int playerId);
}
