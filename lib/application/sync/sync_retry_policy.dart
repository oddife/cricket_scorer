class SyncRetryPolicy {
  const SyncRetryPolicy({
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 10),
  });

  final Duration baseDelay;
  final Duration maxDelay;

  Duration nextDelay(int attempts) {
    if (attempts < 1) return baseDelay;
    final exponent = attempts - 1;
    final multiplier = 1 << (exponent > 10 ? 10 : exponent);
    final delay = Duration(milliseconds: baseDelay.inMilliseconds * multiplier);
    return delay.compareTo(maxDelay) > 0 ? maxDelay : delay;
  }

  DateTime nextAttemptAt({required int attempts, DateTime? now}) =>
      (now ?? DateTime.now().toUtc()).add(nextDelay(attempts));
}
