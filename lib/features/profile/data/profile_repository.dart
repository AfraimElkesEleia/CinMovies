import 'dart:typed_data';

import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:dartz/dartz.dart';

class ProfileRepository {
  const ProfileRepository(
    this._database,
    this._storage, [
    this._errorMapper = defaultErrorMapper,
  ]);

  static const avatarBucket = 'avatars';

  final SupabaseDatabaseService _database;
  final SupabaseStorageService _storage;
  final ErrorMapperRegistry _errorMapper;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<Either<Failure, Map<String, dynamic>?>> currentProfile() async {
    try {
      final profile = await _database
          .from('profiles')
          .select()
          .eq('id', _userId)
          .maybeSingle();
      return Right(profile);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, void>> updateProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
    bool? onboardingCompleted,
  }) async {
    try {
      final values = <String, dynamic>{};
      if (fullName != null) values['full_name'] = fullName;
      if (username != null) values['username'] = username;
      if (avatarUrl != null) values['avatar_url'] = avatarUrl;
      if (bio != null) values['bio'] = bio;
      if (onboardingCompleted != null) {
        values['onboarding_completed'] = onboardingCompleted;
      }

      if (values.isEmpty) return const Right(null);
      await _database.from('profiles').update(values).eq('id', _userId);
      return const Right(null);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, String>> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final path = _storage.userScopedPath(
        bucketFolder: 'profiles',
        fileName: fileName,
      );
      await _storage.uploadBytes(
        bucket: avatarBucket,
        path: path,
        bytes: bytes,
        contentType: contentType,
      );
      final url = _storage.publicUrl(bucket: avatarBucket, path: path);
      await updateProfile(avatarUrl: url);
      return Right(url);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }
}

