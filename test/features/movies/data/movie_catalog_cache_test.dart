import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:cinmovies_app/features/movies/data/movie_artwork_cache.dart';
import 'package:cinmovies_app/features/movies/data/movie_cache_codec.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('MovieCacheCodec', () {
    test('round trips nested movie data', () {
      final movie = _movie(
        '10',
        'Cached Movie',
        cast: const [
          MovieCastMember(
            name: 'Actor',
            character: 'Hero',
            photoUrl: 'https://images.test/actor.jpg',
          ),
        ],
        reviews: const [
          TmdbReview(
            username: 'critic',
            avatarUrl: 'https://images.test/avatar.jpg',
            rating: 8,
            text: 'Great',
            date: '2026-07-20',
            helpful: 4,
            spoiler: true,
          ),
        ],
      );

      final restored = MovieCacheCodec.decode(MovieCacheCodec.encode(movie));

      expect(restored, isNotNull);
      expect(restored!.id, movie.id);
      expect(restored.title, movie.title);
      expect(restored.genres, movie.genres);
      expect(restored.cast.single.name, 'Actor');
      expect(restored.reviews.single.username, 'critic');
      expect(restored.reviews.single.spoiler, isTrue);
    });

    test('rejects malformed movie records', () {
      expect(MovieCacheCodec.decode({'title': 'Missing ID'}), isNull);
      expect(MovieCacheCodec.decode('not a map'), isNull);
    });
  });

  group('persistent catalog repositories', () {
    late Directory tempDirectory;
    late HiveCacheService cache;
    late _CatalogAdapter adapter;
    late Dio dio;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'movie_catalog_cache_test_',
      );
      Hive.init(tempDirectory.path);
      final suffix = DateTime.now().microsecondsSinceEpoch;
      cache = HiveCacheService(
        await Hive.openBox<dynamic>('search_$suffix'),
        await Hive.openBox<dynamic>('movies_$suffix'),
        await Hive.openBox<dynamic>('users_$suffix'),
        await Hive.openBox<dynamic>('genres_$suffix'),
        catalogBox: await Hive.openBox<dynamic>('catalog_$suffix'),
      );
      adapter = _CatalogAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
        ..httpClientAdapter = adapter;
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('Home saves and restores at most 20 movies per section', () async {
      final artworkCache = _BlockingArtworkCache();
      final repository = HomeRepository(
        dio,
        cache,
        artworkCache,
      );

      final result = await repository.fetchHomeMovies();
      final cached = repository.readCachedHomeMovies();

      expect(result.isRight(), isTrue);
      expect(cached, isNotNull);
      expect(cached!.data.popularMovies, hasLength(20));
      expect(cached.data.upcomingMovies, hasLength(20));
      expect(cached.data.popularMovies.first.title, 'Popular 1');
      expect(cached.data.popularMovies.last.title, 'Popular 20');
      expect(artworkCache.movies, hasLength(40));
      artworkCache.complete();

      final restoredRepository = HomeRepository(
        Dio(),
        cache,
      );
      expect(
        restoredRepository
            .readCachedHomeMovies()!
            .data
            .upcomingMovies
            .first
            .title,
        'Upcoming 1',
      );
    });

    test('Home ignores incompatible cache schemas', () async {
      await cache.cacheCatalogEntry('home_feed', {
        'schema_version': 99,
        'cached_at': DateTime.now().toUtc().toIso8601String(),
        'popular': [MovieCacheCodec.encode(_movie('1', 'Old'))],
        'upcoming': const [],
      });

      final repository = HomeRepository(dio, cache);

      expect(repository.readCachedHomeMovies(), isNull);
    });

    test('For You cache requires matching user and genre signature', () async {
      final repository = HomeRepository(dio, cache);

      final result = await repository.fetchForYouMovies(
        genreIds: const [878, 28],
        page: 1,
        cacheScope: 'user-one',
      );

      expect(result.isRight(), isTrue);
      expect(
        repository
            .readCachedForYouMovies(
              scopeId: 'user-one',
              genreIds: const [28, 878],
            )
            ?.page
            .movies
            .single
            .title,
        'For You',
      );
      expect(
        repository.readCachedForYouMovies(
          scopeId: 'user-two',
          genreIds: const [28, 878],
        ),
        isNull,
      );
      expect(
        repository.readCachedForYouMovies(
          scopeId: 'user-one',
          genreIds: const [35],
        ),
        isNull,
      );
    });

    test('details persist and evict the least recently stored record', () async {
      final repository = MovieDetailsRepository(
        dio,
        cache,
      );

      for (var id = 1; id <= 21; id++) {
        final result = await repository.fetchMovieDetails(
          _movie('$id', 'Seed $id'),
        );
        expect(result.isRight(), isTrue);
      }

      final entries = cache.getCatalogEntries('movie_details::');
      expect(entries, hasLength(20));
      expect(entries, isNot(contains('movie_details::1')));
      expect(entries, contains('movie_details::21'));

      final restored = repository.readCachedMovieDetails(
        _movie('21', 'Seed 21'),
      );
      expect(restored, isNotNull);
      expect(restored!.data.movie.title, 'Full 21');
      expect(restored.data.similarMovies.single.title, 'Similar 21');
      expect(restored.data.videoKey, 'video-21');
    });
  });
}

class _BlockingArtworkCache implements MovieArtworkCache {
  final _completer = Completer<void>();
  List<Movie> movies = const [];

  @override
  Future<void> cacheMovies(Iterable<Movie> movies) {
    this.movies = movies.toList();
    return _completer.future;
  }

  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

class _CatalogAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = switch (options.path) {
      '/movie/popular' => {
        'results': [
          for (var id = 1; id <= 25; id++)
            {
              'id': id,
              'title': 'Popular $id',
              'poster_path': '/popular-$id.jpg',
            },
        ],
      },
      '/movie/upcoming' => {
        'results': [
          for (var id = 1; id <= 25; id++)
            {
              'id': id + 100,
              'title': 'Upcoming $id',
              'poster_path': '/upcoming-$id.jpg',
            },
        ],
      },
      '/discover/movie' => {
        'page': 1,
        'total_pages': 3,
        'results': [
          {
            'id': 500,
            'title': 'For You',
            'poster_path': '/for-you.jpg',
            'genre_ids': [28, 878],
          },
        ],
      },
      _ => _detailPayload(options.path),
    };

    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Map<String, Object?> _detailPayload(String path) {
    final id = int.parse(path.split('/').last);
    return {
      'id': id,
      'title': 'Full $id',
      'overview': 'Full overview $id',
      'similar': {
        'results': [
          {'id': id + 1000, 'title': 'Similar $id'},
        ],
      },
      'videos': {
        'results': [
          {
            'site': 'YouTube',
            'type': 'Trailer',
            'official': true,
            'key': 'video-$id',
          },
        ],
      },
    };
  }
}

Movie _movie(
  String id,
  String title, {
  List<MovieCastMember> cast = const [],
  List<TmdbReview> reviews = const [],
}) {
  return Movie(
    id: id,
    title: title,
    imageAsset: 'https://images.test/$id.jpg',
    genres: const ['Drama'],
    rating: 7.5,
    year: '2026',
    duration: '2h',
    ageRating: 'PG-13',
    synopsis: 'Synopsis',
    director: 'Director',
    votes: '1K',
    cast: cast,
    reviews: reviews,
  );
}
