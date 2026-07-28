import 'dart:math';

import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract interface class MovieArtworkCache {
  Future<void> cacheMovies(Iterable<Movie> movies);
}

class DiskMovieArtworkCache implements MovieArtworkCache {
  DiskMovieArtworkCache({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  static const _maxConcurrentDownloads = 4;

  final BaseCacheManager _cacheManager;

  @override
  Future<void> cacheMovies(Iterable<Movie> movies) async {
    final urls = movies
        .map((movie) => movie.imageAsset.trim())
        .where((url) => url.startsWith('http'))
        .toSet()
        .toList();
    if (urls.isEmpty) return;

    var nextIndex = 0;
    Future<void> worker() async {
      while (nextIndex < urls.length) {
        final url = urls[nextIndex++];
        try {
          await _cacheManager.downloadFile(url);
        } catch (_) {
          // Artwork warming is best effort; the widget has its own fallback.
        }
      }
    }

    await Future.wait(
      List.generate(
        min(_maxConcurrentDownloads, urls.length),
        (_) => worker(),
      ),
    );
  }
}
