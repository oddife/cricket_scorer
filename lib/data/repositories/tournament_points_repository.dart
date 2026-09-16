import '../../domain/tournaments/models/tournament_points_rules.dart';

abstract interface class TournamentPointsRepository {
  Future<TournamentPointsRules> get(int tournamentId);
  Future<void> save(TournamentPointsRules rules);
}
