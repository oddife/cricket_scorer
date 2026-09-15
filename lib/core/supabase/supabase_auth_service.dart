import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  const SupabaseAuthService(this._client);

  final SupabaseClient? _client;

  bool get isAvailable => _client != null;

  Session? get session => _client?.auth.currentSession;

  User? get currentUser => _client?.auth.currentUser;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    final client = _requireClient();
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    final client = _requireClient();
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges {
    final client = _requireClient();
    return client.auth.onAuthStateChange;
  }

  SupabaseClient _requireClient() =>
      _client ?? (throw StateError('Supabase is not configured.'));
}
