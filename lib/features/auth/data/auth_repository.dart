import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(
    this._database,
    this._preferences, [
    this._errorMapper = defaultErrorMapper,
  ]);

  final SupabaseDatabaseService _database;
  final LocalPreferencesService _preferences;
  final ErrorMapperRegistry _errorMapper;

  User? get currentUser => _database.currentUser;

  Stream<AuthState> get authStateChanges => _database.authStateChanges;

  Future<String> resolveInitialRoute() async {
    if (!_preferences.hasPassedOnboarding) return Routes.onBoarding;
    return currentUser == null ? Routes.login : Routes.home;
  }

  Future<Either<Failure, AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _database.signInWithPassword(
        email: email,
        password: password,
      );
      return Right(response);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, AuthResponse>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _database.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return Right(response);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<void> signOut() => _database.signOut();
}
