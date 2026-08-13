import 'dart:typed_data';

import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  bool get isAuthenticated;

  bool get isGuest;

  String? get currentUserEmail;

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> continueAsGuest();

  Future<Result<void>> leaveGuestMode();

  Future<Result<void>> signUp({
    required String fullName,
    required String email,
    required String password,
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? avatarContentType,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> updatePassword(String password);
}

final class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(
    this._database,
    this._storage,
    this._preferences,
    this._errorMapper,
  );

  static const avatarBucket = 'avatars';

  final SupabaseDatabaseService _database;
  final SupabaseStorageService _storage;
  final LocalPreferencesService _preferences;
  final ErrorMapper _errorMapper;

  User? get _currentUser => _database.currentUser;

  @override
  bool get isAuthenticated =>
      _currentUser != null && _currentUser?.isAnonymous != true;

  @override
  bool get isGuest =>
      _preferences.isGuestMode || _currentUser?.isAnonymous == true;

  @override
  String? get currentUserEmail => _currentUser?.email;

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) {
    return _errorMapper.capture(() async {
      await _preferences.setGuestMode(false);
      await _database.signInWithPassword(email: email, password: password);
    });
  }

  @override
  Future<Result<void>> continueAsGuest() {
    return _errorMapper.capture(() async {
      if (_currentUser != null) {
        await _database.signOut();
      }
      await _preferences.setGuestMode(true);
    });
  }

  @override
  Future<Result<void>> leaveGuestMode() {
    return _errorMapper.capture(() async {
      if (_currentUser?.isAnonymous == true) {
        await _database.signOut();
      }
      await _preferences.setGuestMode(false);
    });
  }

  @override
  Future<Result<void>> signUp({
    required String fullName,
    required String email,
    required String password,
    Uint8List? avatarBytes,
    String? avatarFileName,
    String? avatarContentType,
  }) {
    return _errorMapper.capture(() async {
      await _preferences.setGuestMode(false);
      await _database.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (avatarBytes != null && _currentUser != null) {
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
    });
  }

  @override
  Future<Result<void>> signOut() {
    return _errorMapper.capture(() async {
      try {
        if (_currentUser != null) {
          await _database.signOut();
        }
      } finally {
        await _preferences.setGuestMode(false);
      }
    });
  }

  @override
  Future<Result<void>> updatePassword(String password) {
    return _errorMapper.capture(() async {
      await _database.updateUser(UserAttributes(password: password));
    });
  }

  Future<String> _uploadSignupAvatar({
    required String fullName,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final userId = _currentUser?.id;
    if (userId == null) throw const AuthenticationRequiredException();

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
