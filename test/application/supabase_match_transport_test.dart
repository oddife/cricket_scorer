import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_scorer/application/sync/supabase_match_transport.dart';

void main() {
  test('match sync id is installation scoped and stable', () {
    expect(
      SupabaseMatchTransport.matchSyncId(
        installationId: 'installation-1',
        matchId: 42,
      ),
      'installation-1:match:42',
    );
  });

  test('innings sync id is installation scoped and stable', () {
    expect(
      SupabaseMatchTransport.inningsSyncId(
        installationId: 'installation-1',
        inningsId: 7,
      ),
      'installation-1:innings:7',
    );
  });
}
