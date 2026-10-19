import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stable match sync id is accepted as a caller-provided identity', () {
    const syncId = '550e8400-e29b-41d4-a716-446655440000';
    expect(syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
  });

  test('stable innings sync id is accepted as a caller-provided identity', () {
    const syncId = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
    expect(syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
  });
}
