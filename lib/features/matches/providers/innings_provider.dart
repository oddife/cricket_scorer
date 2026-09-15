import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../domain/innings/models/innings.dart';
import '../../../domain/scoring/models/ball_event.dart';

final inningsByMatchProvider = FutureProvider.family<List<Innings>, int>(
  (ref, matchId) => ref.watch(inningsRepositoryProvider).getForMatch(matchId),
);

final inningsByMatchAndNumberProvider =
    FutureProvider.family<Innings?, ({int matchId, int inningsNumber})>(
  (ref, args) => ref
      .watch(inningsRepositoryProvider)
      .getByMatchAndNumber(args.matchId, args.inningsNumber),
);

final ballEventsByInningsProvider =
    FutureProvider.family<List<BallEvent>, int>(
  (ref, inningsId) =>
      ref.watch(ballEventRepositoryProvider).getForInnings(inningsId),
);
