import 'dart:async';

/// Serializes local scoring mutations with remote match recovery imports.
class MatchDataMutationLock {
  Future<void> _tail = Future<void>.value();

  Future<T> runExclusive<T>(Future<T> Function() action) async {
    final previous = _tail;
    final release = Completer<void>();
    _tail = release.future;
    await previous;
    try {
      return await action();
    } finally {
      release.complete();
    }
  }
}
