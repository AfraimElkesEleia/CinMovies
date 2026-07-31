import 'dart:io';

import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDirectory;
  late HiveCacheService cache;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'favorite_genres_cache_test_',
    );
    Hive.init(tempDirectory.path);
    cache = HiveCacheService(
      await Hive.openBox<dynamic>('search'),
      await Hive.openBox<dynamic>('movies'),
      await Hive.openBox<dynamic>('users'),
      await Hive.openBox<dynamic>('genres'),
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('keeps favorite genres isolated by user scope', () async {
    await cache.cacheFavoriteGenres({'Action'}, scopeId: 'user-one');
    await cache.cacheFavoriteGenres({'Comedy'}, scopeId: 'user-two');
    await cache.cacheFavoriteGenres({'Drama'});

    expect(
      cache.getFavoriteGenres(scopeId: 'user-one'),
      {'Action'},
    );
    expect(
      cache.getFavoriteGenres(scopeId: 'user-two'),
      {'Comedy'},
    );
    expect(cache.getFavoriteGenres(), {'Drama'});
  });

  test('watcher emits only changes for its scope', () async {
    final expectation = expectLater(
      cache.watchFavoriteGenres(scopeId: 'user-one').take(1),
      emits({'Action', 'Sci-Fi'}),
    );

    await cache.cacheFavoriteGenres({'Comedy'}, scopeId: 'user-two');
    await cache.cacheFavoriteGenres(
      {'Action', 'Sci-Fi'},
      scopeId: 'user-one',
    );

    await expectation;
  });
}
