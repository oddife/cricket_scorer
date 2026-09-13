import '../../domain/teams/models/team.dart';

abstract interface class TeamRepository {
  Future<List<Team>> getAll();
  Future<Team> create(Team team);
  Future<void> update(Team team);
  Future<void> deactivate(int teamId);
}
