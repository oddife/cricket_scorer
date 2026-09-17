import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the shared catalog from Supabase without mutating local Drift data.
/// Pagination keeps the pull safe when a catalog grows beyond the PostgREST
/// default page size.
class SupabaseCatalogPullTransport {
  const SupabaseCatalogPullTransport(this._client);

  final SupabaseClient? _client;

  Future<List<Map<String, dynamic>>> downloadTeams() =>
      _download('teams');

  Future<List<Map<String, dynamic>>> downloadPlayers() =>
      _download('players');

  Future<List<Map<String, dynamic>>> downloadTeamPlayers() =>
      _download('team_players');

  Future<List<Map<String, dynamic>>> downloadTournaments() =>
      _download('tournaments');

  Future<List<Map<String, dynamic>>> downloadTournamentTeams() =>
      _download('tournament_teams');

  Future<List<Map<String, dynamic>>> downloadPointsRules() =>
      _download('tournament_points_rules');

  Future<List<Map<String, dynamic>>> downloadDeleteTombstones() =>
      _download('catalog_delete_tombstones');

  Future<List<Map<String, dynamic>>> _download(String table) async {
    final client = _requireAuthenticatedClient();
    const pageSize = 1000;
    final rows = <Map<String, dynamic>>[];
    var offset = 0;

    while (true) {
      final page = await client
          .from(table)
          .select()
          .range(offset, offset + pageSize - 1);
      final typedPage = List<Map<String, dynamic>>.from(page);
      rows.addAll(typedPage);
      if (typedPage.length < pageSize) break;
      offset += pageSize;
    }

    return rows;
  }

  SupabaseClient _requireAuthenticatedClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured. Catalog remains local.');
    }
    if (client.auth.currentUser == null) {
      throw StateError('Supabase catalog pull requires an authenticated scorer.');
    }
    return client;
  }
}
