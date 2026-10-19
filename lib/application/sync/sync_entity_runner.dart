/// Runs independent synchronization work without allowing one entity failure
/// to block the remaining entities.
class SyncEntityRunner {
  const SyncEntityRunner._();

  static Future<int> run<T>(
    Iterable<T> entities,
    Future<void> Function(T entity) upload,
  ) async {
    var uploaded = 0;
    for (final entity in entities) {
      try {
        await upload(entity);
        uploaded++;
      } catch (_) {
        // A single entity must not block unrelated entities.
      }
    }
    return uploaded;
  }
}
