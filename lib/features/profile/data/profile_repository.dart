import 'dart:typed_data';

import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';

class ProfileRepository {
  const ProfileRepository(this._database, this._storage);

  static const avatarBucket = 'avatars';

  final SupabaseDatabaseService _database;
  final SupabaseStorageService _storage;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<Map<String, dynamic>?> currentProfile() async {
    return _database.from('profiles').select().eq('id', _userId).maybeSingle();
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
    bool? onboardingCompleted,
  }) async {
    final values = <String, dynamic>{};
    if (fullName != null) values['full_name'] = fullName;
    if (username != null) values['username'] = username;
    if (avatarUrl != null) values['avatar_url'] = avatarUrl;
    if (bio != null) values['bio'] = bio;
    if (onboardingCompleted != null) {
      values['onboarding_completed'] = onboardingCompleted;
    }

    if (values.isEmpty) return;
    await _database.from('profiles').update(values).eq('id', _userId);
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
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
    return url;
  }
}
