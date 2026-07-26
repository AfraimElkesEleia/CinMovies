import 'dart:io';

import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late Directory tempDir;
  late HiveCacheService cache;
  late String scopeId;
  late TrailerHistoryRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('trailer_history_test_');
    Hive.init(tempDir.path);
    final suffix = DateTime.now().microsecondsSinceEpoch;
    cache = HiveCacheService(
      await Hive.openBox<dynamic>('search_$suffix'),
      await Hive.openBox<dynamic>('movies_$suffix'),
      await Hive.openBox<dynamic>('users_$suffix'),
      await Hive.openBox<dynamic>('genres_$suffix'),
      trailerHistoryBox: await Hive.openBox<dynamic>('trailers_$suffix'),
    );
    scopeId = 'user-a';
    repository = TrailerHistoryRepository(
      cache,
      SupabaseClient('https://localhost.invalid', 'test-key'),
      scopeIdResolver: () => scopeId,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('history is isolated by account and upserts by video key', () async {
    await repository.saveProgress(_entry(watched: 25, updatedAtSeconds: 1));
    await repository.saveProgress(_entry(watched: 40, updatedAtSeconds: 2));

    final userA = (await repository.history()).getOrElse(() => []);
    expect(userA, hasLength(1));
    expect(userA.single.watchedSeconds, 40);

    scopeId = 'user-b';
    expect((await repository.history()).getOrElse(() => []), isEmpty);
    await repository.saveProgress(_entry(watched: 10, updatedAtSeconds: 3));

    scopeId = 'user-a';
    final restoredUserA = (await repository.history()).getOrElse(() => []);
    expect(restoredUserA.single.watchedSeconds, 40);
  });

  test('invalid records are ignored and progress is clamped', () async {
    await cache.cacheTrailerHistoryEntry('user-a', 'broken', {
      'video_key': 'broken',
      'watched_seconds': 'not-a-number',
      'total_seconds': 100,
    });
    await repository.saveProgress(_entry(watched: 150, updatedAtSeconds: 1));

    final entries = (await repository.history()).getOrElse(() => []);
    expect(entries, hasLength(1));
    expect(entries.single.watchedSeconds, 100);
    expect(entries.single.percentage, 100);
  });

  test('remove deletes only the current account history entry', () async {
    await repository.saveProgress(_entry(watched: 25, updatedAtSeconds: 1));

    scopeId = 'user-b';
    await repository.saveProgress(_entry(watched: 40, updatedAtSeconds: 2));

    scopeId = 'user-a';
    final result = await repository.remove('video-key');

    expect(result.isRight(), isTrue);
    expect((await repository.history()).getOrElse(() => []), isEmpty);

    scopeId = 'user-b';
    expect((await repository.history()).getOrElse(() => []), hasLength(1));
  });
}

TrailerHistoryEntry _entry({
  required int watched,
  required int updatedAtSeconds,
}) {
  return TrailerHistoryEntry(
    videoKey: 'video-key',
    movieId: '10',
    title: 'Movie Trailer',
    imageAsset: 'assets/images/movie_ex1.jpg',
    watchedSeconds: watched,
    totalSeconds: 100,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      updatedAtSeconds * 1000,
      isUtc: true,
    ),
  );
}
