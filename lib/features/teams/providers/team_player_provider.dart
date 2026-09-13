import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/players/models/player.dart';
import '../../../domain/teams/models/team_player.dart';

final teamPlayersProvider = FutureProvider.family<List<Player>, int>((ref, teamId) {
  return ref.watch(teamPlayerRepositoryProvider).getPlayersForTeam(teamId);
});

final teamPlayerRepositoryProvider = Provider((ref) {
  return ref.watch(appDatabaseProvider).teamPlayerRepository;
});
