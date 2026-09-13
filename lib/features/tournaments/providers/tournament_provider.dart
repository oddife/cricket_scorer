import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/tournaments/enums/tournament_type.dart';
import '../../../domain/tournaments/models/tournament.dart';

final tournamentProvider = NotifierProvider<TournamentNotifier, List<Tournament>>(
  TournamentNotifier.new,
);

class TournamentNotifier extends Notifier<List<Tournament>> {
  @override
  List<Tournament> build() => const [];

  void add({
    required String name,
    required TournamentType type,
    String? logoPath,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final tournament = Tournament(
      id: DateTime.now().microsecondsSinceEpoch,
      name: name.trim(),
      type: type,
      logoPath: logoPath,
      startDate: startDate,
      endDate: endDate,
    );

    state = [tournament, ...state];
  }
}