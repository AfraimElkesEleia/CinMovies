import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(this._database, this._preferences);

  final SupabaseDatabaseService _database;
  final LocalPreferencesService _preferences;

  User? get currentUser => _database.currentUser;

  Stream<AuthState> get authStateChanges => _database.authStateChanges;

  Future<String> resolveInitialRoute() async {
    if (!_preferences.hasPassedOnboarding) return Routes.onBoarding;
    return currentUser == null ? Routes.login : Routes.home;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _database.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _database.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signOut() => _database.signOut();
}
