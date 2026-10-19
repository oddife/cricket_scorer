import '../../domain/innings/models/innings.dart';

abstract interface class InningsRepository {
  Future<Innings?> getById(int inningsId);
  Future<Innings?> getByMatchAndNumber(int matchId, int inningsNumber);
  Future<List<Innings>> getForMatch(int matchId);
  Future<Innings> create(Innings innings);
  Future<void> update(Innings innings);
}
