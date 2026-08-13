import 'dart:typed_data';

import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/exceptions.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:cinmovies_app/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile?>> currentProfile();

  Future<Result<void>> updateProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
    bool? onboardingCompleted,
    bool clearUsername = false,
    bool clearBio = false,
  });

  Future<Result<String>> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  });
}

final class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(
    this._database,
    this._storage,
    this._errorMapper,
  );

  static const avatarBucket = 'avatars';

  final SupabaseDatabaseService _database;
  final SupabaseStorageService _storage;
  final ErrorMapper _errorMapper;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw const AuthenticationRequiredException();
    return id;
  }

  @override
  Future<Result<UserProfile?>> currentProfile() {
    return _errorMapper.capture(() async {
      final profile = await _database
          .from('profiles')
          .select()
          .eq('id', _userId)
          .maybeSingle();
      return profile == null ? null : UserProfile.fromMap(profile);
    });
  }

  @override
  Future<Result<void>> updateProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
    bool? onboardingCompleted,
    bool clearUsername = false,
    bool clearBio = false,
  }) {
    return _errorMapper.capture(() async {
      final values = <String, dynamic>{};
      if (fullName != null) values['full_name'] = fullName;
      if (username != null || clearUsername) {
        values['username'] = clearUsername ? null : username;
      }
      if (avatarUrl != null) values['avatar_url'] = avatarUrl;
      if (bio != null || clearBio) values['bio'] = clearBio ? null : bio;
      if (onboardingCompleted != null) {
        values['onboarding_completed'] = onboardingCompleted;
      }

      if (values.isEmpty) return;
      await _database.from('profiles').update(values).eq('id', _userId);
    });
  }

  @override
  Future<Result<String>> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final uploadResult = await _errorMapper.capture(() async {
      final path = _storage.userScopedPath(
        bucketFolder: 'profiles',
        fileName: _timestampedFileName(fileName),
      );
      await _storage.uploadBytes(
        bucket: avatarBucket,
        path: path,
        bytes: bytes,
        contentType: contentType,
        upsert: false,
      );
      final url = _storage.publicUrl(bucket: avatarBucket, path: path);
      return url;
    });

    return uploadResult.flatMapAsync((url) async {
      final updateResult = await updateProfile(avatarUrl: url);
      return updateResult.map((_) => url);
    });
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
