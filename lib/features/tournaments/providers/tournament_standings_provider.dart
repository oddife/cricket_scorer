import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/tournaments/models/tournament_standing.dart';
import '../../matches/providers/match_provider.dart';
import '../services/tournament_standings_service.dart';
import 'tournament_provider.dart';
import 'tournament_team_provider.dart';

final tournamentStandingsProvider = FutureProvider.family<List<TournamentStanding>, int>(
  (ref, tournamentId) async {
    ref.watch(matchProvider);
    ref.watch(tournamentPointsRulesProvider(tournamentId));
    ref.watch(tournamentTeamsProvider(tournamentId));
    final service = TournamentStandingsService(
      matchRepository: ref.watch(matchRepositoryProvider),
      inningsRepository: ref.watch(inningsRepositoryProvider),
      ballEventRepository: ref.watch(ballEventRepositoryProvider),
      tournamentTeamRepository: ref.watch(tournamentTeamRepositoryProvider),
      pointsRepository: ref.watch(tournamentPointsRepositoryProvider),
    );
    return service.calculate(tournamentId);
  },
);
