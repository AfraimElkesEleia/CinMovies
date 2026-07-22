import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  const SupabaseStorageService(this._client);

  final SupabaseClient _client;

  String userScopedPath({
    required String bucketFolder,
    required String fileName,
  }) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user.');
    return '$bucketFolder/$userId/$fileName';
  }

  Future<String> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
    bool upsert = true,
  }) {
    return _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: upsert),
        );
  }

  String publicUrl({required String bucket, required String path}) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> signedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) {
    return _client.storage.from(bucket).createSignedUrl(path, expiresInSeconds);
  }

  Future<void> delete({
    required String bucket,
    required List<String> paths,
  }) async {
    await _client.storage.from(bucket).remove(paths);
  }
}
