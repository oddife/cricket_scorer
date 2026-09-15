import 'package:flutter_test/flutter_test.dart';

import '../../lib/application/sync/sync_retry_policy.dart';

void main() {
  const policy = SyncRetryPolicy(
    baseDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 10),
  );

  test('starts at the base delay', () {
    expect(policy.nextDelay(1), const Duration(seconds: 2));
  });

  test('doubles until the maximum delay', () {
    expect(policy.nextDelay(2), const Duration(seconds: 4));
    expect(policy.nextDelay(3), const Duration(seconds: 8));
    expect(policy.nextDelay(4), const Duration(seconds: 10));
    expect(policy.nextDelay(8), const Duration(seconds: 10));
  });

  test('calculates the next attempt from the supplied time', () {
    final now = DateTime.utc(2026, 9, 15, 10);
    expect(
      policy.nextAttemptAt(attempts: 3, now: now),
      DateTime.utc(2026, 9, 15, 10, 0, 0).add(const Duration(seconds: 8)),
    );
  });
}
