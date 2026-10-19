import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_scorer/application/sync/match_data_mutation_lock.dart';

void main() {
  test('serializes local scoring with a recovery import', () async {
    final lock = MatchDataMutationLock();
    final releaseImport = Completer<void>();
    final order = <String>[];

    final import = lock.runExclusive(() async {
      order.add('import:start');
      await releaseImport.future;
      order.add('import:end');
    });
    final scoring = lock.runExclusive(() async {
      order.add('score:write');
    });

    await Future<void>.delayed(Duration.zero);
    expect(order, ['import:start']);

    releaseImport.complete();
    await Future.wait([import, scoring]);
    expect(order, ['import:start', 'import:end', 'score:write']);
  });
}
