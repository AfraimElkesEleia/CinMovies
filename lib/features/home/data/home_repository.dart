import 'dart:async';

import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:cinmovies_app/features/movies/data/movie_artwork_cache.dart';
import 'package:cinmovies_app/features/movies/data/movie_cache_codec.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HomeRepository {
  const HomeRepository(
    this._dio, [
    this._cache,
    this._artworkCache,
  ]);

  static const _homeFeedCacheKey = 'home_feed';
  static const _forYouCacheKeyPrefix = 'home_for_you::';
  static const _cacheSchemaVersion = 1;
  static const _forYouCacheSchemaVersion = 1;
  static const _sectionCacheLimit = 20;

  final Dio _dio;
  final HiveCacheService? _cache;
  final MovieArtworkCache? _artworkCache;

  CachedHomeFeed? readCachedHomeMovies() {
    final cache = _cache;
    if (cache == null) return null;

    try {
      final json = cache.getCatalogEntry(_homeFeedCacheKey);
      if (json == null || json['schema_version'] != _cacheSchemaVersion) {
        return null;
      }

      final cachedAt = DateTime.tryParse(json['cached_at'] as String? ?? '');
      final popular = MovieCacheCodec.decodeList(json['popular']);
      final upcoming = MovieCacheCodec.decodeList(json['upcoming']);
      if (cachedAt != null && (popular.isNotEmpty || upcoming.isNotEmpty)) {
        return CachedHomeFeed(
          data: HomeFeedData(
            popularMovies: popular,
            upcomingMovies: upcoming,
          ),
          cachedAt: cachedAt,
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<Either<Failure, HomeFeedData>> fetchHomeMovies() async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>(
          ApiConstants.popularMovies,
          queryParameters: _queryParameters(),
        ),
        _dio.get<Map<String, dynamic>>(
          ApiConstants.upcomingMovies,
          queryParameters: _queryParameters(),
        ),
      ]);

      final data = HomeFeedData(
        popularMovies: TmdbMovieMapper.listFromResponse(
          responses[0].data,
        ).take(_sectionCacheLimit).toList(),
        upcomingMovies: TmdbMovieMapper.listFromResponse(
          responses[1].data,
        ).take(_sectionCacheLimit).toList(),
      );
      await _cacheHomeFeed(data);
      unawaited(_warmArtwork(data));
      return Right(data);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<Either<Failure, MovieSectionPage>> fetchMovieSection({
    required HomeMovieSection section,
    required int page,
    List<int> genreIds = const [],
  }) async {
    if (section == HomeMovieSection.forYou) {
      return fetchForYouMovies(genreIds: genreIds, page: page);
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        section.path,
        queryParameters: _queryParameters(page),
      );

      return Right(MovieSectionPage.fromJson(response.data));
    } catch (error) {
      return Left(mapError(error));
    }
  }

  CachedMovieSection? readCachedForYouMovies({
    required String scopeId,
    required List<int> genreIds,
  }) {
    final cache = _cache;
    final normalizedIds = _normalizedGenreIds(genreIds);
    if (cache == null || normalizedIds.isEmpty) return null;

    try {
      final json = cache.getCatalogEntry(
        _forYouCacheKey(scopeId, normalizedIds),
      );
      if (json == null ||
          json['schema_version'] != _forYouCacheSchemaVersion) {
        return null;
      }

      final cachedIds = (json['genre_ids'] as Iterable?)
          ?.whereType<num>()
          .map((id) => id.toInt())
          .toList();
      if (cachedIds == null ||
          cachedIds.join('|') != normalizedIds.join('|')) {
        return null;
      }

      final cachedAt = DateTime.tryParse(json['cached_at'] as String? ?? '');
      final movies = MovieCacheCodec.decodeList(json['movies']);
      if (cachedAt == null || movies.isEmpty) return null;

      return CachedMovieSection(
        page: MovieSectionPage(
          movies: movies,
          page: 1,
          totalPages: ((json['total_pages'] as num?) ?? 1).toInt(),
        ),
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Either<Failure, MovieSectionPage>> fetchForYouMovies({
    required List<int> genreIds,
    required int page,
    String? cacheScope,
  }) async {
    final normalizedIds = _normalizedGenreIds(genreIds);
    if (normalizedIds.isEmpty) {
      return const Right(
        MovieSectionPage(movies: [], page: 1, totalPages: 1),
      );
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.discoverMovies,
        queryParameters: _forYouQueryParameters(normalizedIds, page),
      );
      final sectionPage = MovieSectionPage.fromJson(response.data);

      if (page == 1 && cacheScope != null && cacheScope.trim().isNotEmpty) {
        await _cacheForYouMovies(
          scopeId: cacheScope,
          genreIds: normalizedIds,
          page: sectionPage,
        );
      }
      unawaited(_warmMovieArtwork(sectionPage.movies));
      return Right(sectionPage);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Map<String, Object> _queryParameters([int page = 1]) {
    return {'language': 'en-US', 'page': page};
  }

  Map<String, Object> _forYouQueryParameters(
    List<int> genreIds,
    int page,
  ) {
    return {
      'language': 'en-US',
      'page': page,
      'sort_by': 'popularity.desc',
      'include_adult': false,
      'include_video': false,
      'with_genres': genreIds.join('|'),
    };
  }

  Future<void> _cacheHomeFeed(HomeFeedData data) async {
    final cache = _cache;
    if (cache == null) return;
    try {
      await cache.cacheCatalogEntry(_homeFeedCacheKey, {
        'schema_version': _cacheSchemaVersion,
        'cached_at': DateTime.now().toUtc().toIso8601String(),
        'popular': data.popularMovies.map(MovieCacheCodec.encode).toList(),
        'upcoming': data.upcomingMovies.map(MovieCacheCodec.encode).toList(),
      });
    } catch (_) {
      // Fresh network data remains valid even if persistence is unavailable.
    }
  }

  Future<void> _warmArtwork(HomeFeedData data) async {
    await _warmMovieArtwork([
      ...data.popularMovies,
      ...data.upcomingMovies,
    ]);
  }

  Future<void> _warmMovieArtwork(Iterable<Movie> movies) async {
    final artworkCache = _artworkCache;
    if (artworkCache == null) return;
    try {
      await artworkCache.cacheMovies(movies);
    } catch (_) {
      // Artwork warming must never affect catalog loading.
    }
  }

  Future<void> _cacheForYouMovies({
    required String scopeId,
    required List<int> genreIds,
    required MovieSectionPage page,
  }) async {
    final cache = _cache;
    if (cache == null) return;

    try {
      if (page.movies.isEmpty) {
        await cache.deleteCatalogEntry(_forYouCacheKey(scopeId, genreIds));
        return;
      }
      await cache.cacheCatalogEntry(_forYouCacheKey(scopeId, genreIds), {
        'schema_version': _forYouCacheSchemaVersion,
        'cached_at': DateTime.now().toUtc().toIso8601String(),
        'genre_ids': genreIds,
        'total_pages': page.totalPages,
        'movies': page.movies
            .take(_sectionCacheLimit)
            .map(MovieCacheCodec.encode)
            .toList(),
      });
    } catch (_) {
      // Fresh network data remains valid even if persistence is unavailable.
    }
  }

  String _forYouCacheKey(String scopeId, List<int> genreIds) {
    return '$_forYouCacheKeyPrefix$scopeId::${genreIds.join('-')}';
  }

  List<int> _normalizedGenreIds(Iterable<int> genreIds) {
    final normalized = genreIds.where((id) => id > 0).toSet().toList()..sort();
    return normalized;
  }
}

enum HomeMovieSection {
  forYou('For You', ApiConstants.discoverMovies),
  popular('Trending Now', ApiConstants.popularMovies),
  upcoming('New Releases', ApiConstants.upcomingMovies);

  const HomeMovieSection(this.title, this.path);

  final String title;
  final String path;
}

class HomeFeedData {
  const HomeFeedData({
    required this.popularMovies,
    required this.upcomingMovies,
  });

  final List<Movie> popularMovies;
  final List<Movie> upcomingMovies;
}

class CachedHomeFeed {
  const CachedHomeFeed({required this.data, required this.cachedAt});

  final HomeFeedData data;
  final DateTime cachedAt;
}

class CachedMovieSection {
  const CachedMovieSection({required this.page, required this.cachedAt});

  final MovieSectionPage page;
  final DateTime cachedAt;
}

class MovieSectionPage {
  const MovieSectionPage({
    required this.movies,
    required this.page,
    required this.totalPages,
  });

  factory MovieSectionPage.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      return const MovieSectionPage(movies: [], page: 1, totalPages: 1);
    }

    return MovieSectionPage(
      movies: TmdbMovieMapper.listFromResponse(data),
      page: ((data['page'] as num?) ?? 1).toInt(),
      totalPages: ((data['total_pages'] as num?) ?? 1).toInt(),
    );
  }

  final List<Movie> movies;
  final int page;
  final int totalPages;
}
