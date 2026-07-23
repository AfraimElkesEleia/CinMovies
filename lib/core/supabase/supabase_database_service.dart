import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatabaseService {
  const SupabaseDatabaseService(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserResponse> updateUser(UserAttributes attributes) {
    return _client.auth.updateUser(attributes);
  }

  SupabaseQueryBuilder from(String table) => _client.from(table);

  PostgrestFilterBuilder<dynamic> rpc(
    String function, {
    Map<String, dynamic>? params,
  }) {
    return _client.rpc<dynamic>(function, params: params);
  }
}
