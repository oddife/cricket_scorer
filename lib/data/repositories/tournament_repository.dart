import '../../domain/tournaments/models/tournament.dart';

abstract interface class TournamentRepository {
  Future<List<Tournament>> getAll();
  Future<List<Tournament>> getAllIncludingInactive();
  Future<Tournament> create(Tournament tournament);
  Future<void> update(Tournament tournament);
  Future<void> deactivate(int tournamentId);
}
