import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/matches/man_of_match_suggestion_service.dart';
import '../../../core/database/database_provider.dart';
import 'innings_provider.dart';

final manOfMatchSuggestionProvider =
    FutureProvider.family<ManOfMatchContribution?, int>((ref, matchId) async {
  final innings = await ref.watch(inningsByMatchProvider(matchId).future);
  if (innings.isEmpty) return null;

  final repository = ref.watch(ballEventRepositoryProvider);
  final ballsByInnings = <int, List<dynamic>>{};
  for (final inning in innings) {
    ballsByInnings[inning.id] = await repository.getForInnings(inning.id);
  }

  return const ManOfMatchSuggestionService().suggest(
    innings: innings,
    ballsByInnings: ballsByInnings.map(
      (id, balls) => MapEntry(
        id,
        balls.cast(),
      ),
    ),
  );
});
