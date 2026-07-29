import 'dart:typed_data';

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
    this._preferences,
  );

  static const avatarBucket = 'avatars';

  final SupabaseDatabaseService _database;
  final SupabaseStorageService _storage;
  final LocalPreferencesService _preferences;

  User? get currentUser => _database.currentUser;

  bool get isGuest =>
      _preferences.isGuestMode || currentUser?.isAnonymous == true;

  Stream<AuthState> get authStateChanges => _database.authStateChanges;

  Future<String> resolveInitialRoute() async {
    if (!_preferences.hasPassedOnboarding) return AppRoutes.onboarding;
    return currentUser == null && !_preferences.isGuestMode
        ? AppRoutes.login
        : AppRoutes.home;
  }

  Future<Either<Failure, AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _preferences.setGuestMode(false);
      final response = await _database.signInWithPassword(
        email: email,
        password: password,
      );
      return Right(response);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> continueAsGuest() async {
    try {
      if (currentUser != null) {
        await _database.signOut();
      }
      await _preferences.setGuestMode(true);
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, void>> leaveGuestMode() async {
    try {
      if (currentUser?.isAnonymous == true) {
        await _database.signOut();
      }
      await _preferences.setGuestMode(false);
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
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
      await _preferences.setGuestMode(false);
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
      return Left(mapError(error));
    }
  }

  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        await _database.signOut();
      }
    } finally {
      await _preferences.setGuestMode(false);
    }
  }

  Future<Either<Failure, void>> updatePassword(String password) async {
    try {
      await _database.updateUser(UserAttributes(password: password));
      return const Right(null);
    } catch (error) {
      return Left(mapError(error));
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
