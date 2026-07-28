import 'dart:async';

import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/error/default_error_mapper.dart';
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
    this._errorMapper = defaultErrorMapper,
    this._cache,
    this._artworkCache,
  ]);

  static const _homeFeedCacheKey = 'home_feed';
  static const _cacheSchemaVersion = 1;
  static const _sectionCacheLimit = 20;

  final Dio _dio;
  final ErrorMapperRegistry _errorMapper;
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
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, MovieSectionPage>> fetchMovieSection({
    required HomeMovieSection section,
    required int page,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        section.path,
        queryParameters: _queryParameters(page),
      );

      return Right(MovieSectionPage.fromJson(response.data));
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Map<String, Object> _queryParameters([int page = 1]) {
    return {'language': 'en-US', 'page': page};
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
    final artworkCache = _artworkCache;
    if (artworkCache == null) return;
    try {
      await artworkCache.cacheMovies([
        ...data.popularMovies,
        ...data.upcomingMovies,
      ]);
    } catch (_) {
      // Artwork warming must never affect catalog loading.
    }
  }
}

enum HomeMovieSection {
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
