import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/application/sync/sync_entity_runner.dart';

void main() {
  test('uploads every entity when all uploads succeed', () async {
    final uploaded = <int>[];

    final count = await SyncEntityRunner.run<int>(
      [1, 2, 3],
      (entity) async => uploaded.add(entity),
    );

    expect(count, 3);
    expect(uploaded, [1, 2, 3]);
  });

  test('one failed entity does not block later entities', () async {
    final uploaded = <int>[];

    final count = await SyncEntityRunner.run<int>(
      [1, 2, 3],
      (entity) async {
        if (entity == 2) {
          throw StateError('temporary failure');
        }
        uploaded.add(entity);
      },
    );

    expect(count, 2);
    expect(uploaded, [1, 3]);
  });

  test('a failed entity is not counted as uploaded', () async {
    final count = await SyncEntityRunner.run<int>(
      [1],
      (_) async => throw StateError('upload failed'),
    );

    expect(count, 0);
  });

  test('an empty entity list performs no uploads', () async {
    var calls = 0;

    final count = await SyncEntityRunner.run<int>(
      const [],
      (_) async => calls++,
    );

    expect(count, 0);
    expect(calls, 0);
  });
}
