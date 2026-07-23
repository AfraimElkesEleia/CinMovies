import 'dart:typed_data';

import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(
    this._database,
    this._storage,
    this._preferences, [
    this._errorMapper = defaultErrorMapper,
  ]);

  static const avatarBucket = 'avatars';

  final SupabaseDatabaseService _database;
  final SupabaseStorageService _storage;
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
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? avatarContentType,
  }) async {
    try {
      final response = await _database.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (avatarBytes != null && _database.currentUser != null) {
        try {
          final avatarUrl = await _uploadSignupAvatar(
            fullName: fullName,
            bytes: avatarBytes,
            fileName: avatarFileName ?? 'profile-image.jpg',
            contentType: avatarContentType,
          );
          await _database.updateUser(
            UserAttributes(
              data: {'full_name': fullName, 'avatar_url': avatarUrl},
            ),
          );
        } on Object {
          // Profile images are optional. Do not fail an already-created account
          // because the storage upload was rejected.
        }
      }
      return Right(response);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<void> signOut() => _database.signOut();

  Future<Either<Failure, void>> updatePassword(String password) async {
    try {
      await _database.updateUser(UserAttributes(password: password));
      return const Right(null);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<String> _uploadSignupAvatar({
    required String fullName,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final userId = _database.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user.');

    final path = 'profiles/$userId/${_timestampedFileName(fileName)}';
    await _storage.uploadBytes(
      bucket: avatarBucket,
      path: path,
      bytes: bytes,
      contentType: contentType,
      upsert: false,
    );
    final avatarUrl = _storage.publicUrl(bucket: avatarBucket, path: path);

    await _database.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    }, onConflict: 'id');

    return avatarUrl;
  }

  String _timestampedFileName(String fileName) {
    final sanitized = fileName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final fallback = sanitized.isEmpty ? 'profile-image.jpg' : sanitized;
    return '${DateTime.now().millisecondsSinceEpoch}-$fallback';
  }
}
