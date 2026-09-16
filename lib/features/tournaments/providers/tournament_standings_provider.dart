import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/tournaments/models/tournament_standing.dart';
import '../services/tournament_standings_service.dart';

final tournamentStandingsProvider = FutureProvider.family<List<TournamentStanding>, int>(
  (ref, tournamentId) async {
    final service = TournamentStandingsService(
      matchRepository: ref.watch(matchRepositoryProvider),
      inningsRepository: ref.watch(inningsRepositoryProvider),
      ballEventRepository: ref.watch(ballEventRepositoryProvider),
      teamRepository: ref.watch(teamRepositoryProvider),
      tournamentTeamRepository: ref.watch(tournamentTeamRepositoryProvider),
      pointsRepository: ref.watch(tournamentPointsRepositoryProvider),
    );
    return service.calculate(tournamentId);
  },
);
