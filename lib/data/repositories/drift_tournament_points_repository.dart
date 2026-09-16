import 'package:drift/drift.dart';

import '../../domain/tournaments/models/tournament_points_rules.dart';
import '../database/app_database.dart' as db;
import 'tournament_points_repository.dart';

class DriftTournamentPointsRepository implements TournamentPointsRepository {
  DriftTournamentPointsRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<TournamentPointsRules> get(int tournamentId) async {
    final rows = await _database.customSelect(
      'SELECT win_points, tie_points, no_result_points, loss_points '
      'FROM tournament_points_rules WHERE tournament_id = ?',
      variables: [Variable.withInt(tournamentId)],
    ).get();

    if (rows.isEmpty) return TournamentPointsRules(tournamentId: tournamentId);
    final row = rows.first;
    return TournamentPointsRules(
      tournamentId: tournamentId,
      winPoints: row.read<int>('win_points'),
      tiePoints: row.read<int>('tie_points'),
      noResultPoints: row.read<int>('no_result_points'),
      lossPoints: row.read<int>('loss_points'),
    );
  }

  @override
  Future<void> save(TournamentPointsRules rules) async {
    _validate(rules);
    await _database.customStatement(
      '''
      INSERT INTO tournament_points_rules
        (tournament_id, win_points, tie_points, no_result_points, loss_points)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(tournament_id) DO UPDATE SET
        win_points = excluded.win_points,
        tie_points = excluded.tie_points,
        no_result_points = excluded.no_result_points,
        loss_points = excluded.loss_points
      ''',
      [
        rules.tournamentId,
        rules.winPoints,
        rules.tiePoints,
        rules.noResultPoints,
        rules.lossPoints,
      ],
    );
  }

  void _validate(TournamentPointsRules rules) {
    if (rules.tournamentId <= 0) {
      throw ArgumentError('Tournament ID must be positive.');
    }
    for (final points in [
      rules.winPoints,
      rules.tiePoints,
      rules.noResultPoints,
      rules.lossPoints,
    ]) {
      if (points < 0 || points > 99) {
        throw ArgumentError('Points must be between 0 and 99.');
      }
    }
  }
}
