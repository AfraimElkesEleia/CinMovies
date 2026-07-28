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

class MovieDetailsRepository {
  MovieDetailsRepository(
    this._dio, [
    this._cache,
    this._artworkCache,
  ]);

  static const _detailsKeyPrefix = 'movie_details::';
  static const _cacheSchemaVersion = 1;
  static const _detailsCacheLimit = 20;

  final Dio _dio;
  final HiveCacheService? _cache;
  final MovieArtworkCache? _artworkCache;

  CachedMovieDetails? readCachedMovieDetails(Movie seed) {
    final cache = _cache;
    if (cache == null) return null;

    try {
      final key = '$_detailsKeyPrefix${seed.id}';
      final json = cache.getCatalogEntry(key);
      if (json == null || json['schema_version'] != _cacheSchemaVersion) {
        return null;
      }

      final cachedAt = DateTime.tryParse(json['cached_at'] as String? ?? '');
      final movie = MovieCacheCodec.decode(json['movie']);
      if (cachedAt == null || movie == null) return null;

      final details = MovieDetailsData(
        movie: movie,
        similarMovies: MovieCacheCodec.decodeList(json['similar_movies']),
        videoKey: json['video_key'] as String?,
      );
      unawaited(_touchDetails(cache, key, json));
      return CachedMovieDetails(data: details, cachedAt: cachedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> _touchDetails(
    HiveCacheService cache,
    String key,
    Map<String, dynamic> json,
  ) async {
    try {
      await cache.cacheCatalogEntry(key, {
        ...json,
        'last_accessed_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // LRU metadata is best effort.
    }
  }

  Future<Either<Failure, MovieDetailsData>> fetchMovieDetails(
    Movie seed,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.movieDetails}/${seed.id}',
        queryParameters: const {
          'language': 'en-US',
          'append_to_response': 'credits,reviews,similar,videos',
        },
      );

      final result = MovieDetailsData.fromJson(response.data, seed);
      await _cacheDetails(result);
      unawaited(_warmArtwork(result));
      return Right(result);
    } catch (error) {
      return Left(mapError(error));
    }
  }

  Future<void> _cacheDetails(MovieDetailsData details) async {
    final cache = _cache;
    if (cache == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await cache.cacheCatalogEntry(
        '$_detailsKeyPrefix${details.movie.id}',
        {
          'schema_version': _cacheSchemaVersion,
          'cached_at': now,
          'last_accessed_at': now,
          'movie': MovieCacheCodec.encode(details.movie),
          'similar_movies': details.similarMovies
              .map(MovieCacheCodec.encode)
              .toList(),
          'video_key': details.videoKey,
        },
      );
      await _evictOldDetails(cache);
    } catch (_) {
      // Fresh network details remain valid if persistence is unavailable.
    }
  }

  Future<void> _evictOldDetails(HiveCacheService cache) async {
    final entries = cache.getCatalogEntries(_detailsKeyPrefix).entries.toList();
    if (entries.length <= _detailsCacheLimit) return;

    entries.sort((a, b) {
      final aAccessed = _cacheDate(a.value);
      final bAccessed = _cacheDate(b.value);
      return aAccessed.compareTo(bAccessed);
    });
    for (final entry in entries.take(entries.length - _detailsCacheLimit)) {
      await cache.deleteCatalogEntry(entry.key);
    }
  }

  DateTime _cacheDate(Map<String, dynamic> value) {
    return DateTime.tryParse(
          value['last_accessed_at'] as String? ??
              value['cached_at'] as String? ??
              '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<void> _warmArtwork(MovieDetailsData details) async {
    final artworkCache = _artworkCache;
    if (artworkCache == null) return;
    try {
      await artworkCache.cacheMovies([
        details.movie,
        ...details.similarMovies,
      ]);
    } catch (_) {
      // Artwork warming must never affect detail loading.
    }
  }
}

class CachedMovieDetails {
  const CachedMovieDetails({required this.data, required this.cachedAt});

  final MovieDetailsData data;
  final DateTime cachedAt;
}

class MovieDetailsData {
  const MovieDetailsData({
    required this.movie,
    required this.similarMovies,
    this.videoKey,
  });

  factory MovieDetailsData.fromJson(Map<String, dynamic>? json, Movie seed) {
    if (json == null) {
      return MovieDetailsData(movie: seed, similarMovies: const []);
    }

    return MovieDetailsData(
      movie: _movieFromJson(json, seed),
      similarMovies: TmdbMovieMapper.listFromResponse(json['similar']),
      videoKey: _videoKey(json['videos']),
    );
  }

  final Movie movie;
  final List<Movie> similarMovies;
  final String? videoKey;

  static String? _videoKey(Object? videos) {
    if (videos is! Map<String, dynamic>) return null;
    final results = videos['results'];
    if (results is! List) return null;

    final youtubeVideos = results.whereType<Map<String, dynamic>>().where((
      video,
    ) {
      final key = (video['key'] as String?)?.trim() ?? '';
      return key.isNotEmpty &&
          (video['site'] as String?)?.toLowerCase() == 'youtube';
    }).toList();

    Map<String, dynamic>? firstWhere(bool Function(Map<String, dynamic>) test) {
      for (final video in youtubeVideos) {
        if (test(video)) return video;
      }
      return null;
    }

    bool isType(Map<String, dynamic> video, String type) {
      return (video['type'] as String?)?.toLowerCase() == type.toLowerCase();
    }

    bool isOfficial(Map<String, dynamic> video) => video['official'] == true;

    final selected =
        firstWhere((video) => isType(video, 'Trailer') && isOfficial(video)) ??
        firstWhere((video) => isType(video, 'Trailer')) ??
        firstWhere((video) => isType(video, 'Teaser') && isOfficial(video)) ??
        (youtubeVideos.isEmpty ? null : youtubeVideos.first);
    return (selected?['key'] as String?)?.trim();
  }

  static Movie _movieFromJson(Map<String, dynamic> json, Movie seed) {
    final voteCount = (json['vote_count'] as num?)?.toInt();
    final runtime = (json['runtime'] as num?)?.toInt();

    return Movie(
      id: (json['id'] as num?)?.toInt().toString() ?? seed.id,
      title:
          (json['title'] as String?) ??
          (json['original_title'] as String?) ??
          seed.title,
      imageAsset: _imageUrl(
        (json['backdrop_path'] as String?) ??
            (json['poster_path'] as String?) ??
            seed.imageAsset,
      ),
      genres: _genres(json['genres'], seed.genres),
      rating: ((json['vote_average'] as num?) ?? seed.rating).toDouble(),
      year: _yearFromDate(json['release_date'] as String?, seed.year),
      duration: _duration(runtime, seed.duration),
      ageRating: seed.ageRating,
      synopsis: (json['overview'] as String?)?.trim().isNotEmpty == true
          ? (json['overview'] as String).trim()
          : seed.synopsis,
      director: _director(json['credits'], seed.director),
      votes: _formatVotes(voteCount, seed.votes),
      cast: _cast(json['credits'], seed.cast),
      reviews: _reviews(json['reviews'], seed.reviews),
    );
  }

  static String _imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'assets/images/movie_ex1.jpg';
    }
    if (path.startsWith('http') || path.startsWith('assets/')) return path;
    return '${ApiConstants.imageBaseUrl}$path';
  }

  static List<String> _genres(Object? value, List<String> fallback) {
    if (value is! List) return fallback;
    final genres = value
        .whereType<Map<String, dynamic>>()
        .map((genre) => genre['name'] as String?)
        .whereType<String>()
        .toList();
    return genres.isEmpty ? fallback : genres;
  }

  static String _director(Object? credits, String fallback) {
    if (credits is! Map<String, dynamic>) return fallback;
    final crew = credits['crew'];
    if (crew is! List) return fallback;
    for (final member in crew.whereType<Map<String, dynamic>>()) {
      if (member['job'] == 'Director') {
        return member['name'] as String? ?? fallback;
      }
    }
    return fallback;
  }

  static List<MovieCastMember> _cast(
    Object? credits,
    List<MovieCastMember> fallback,
  ) {
    if (credits is! Map<String, dynamic>) return fallback;
    final cast = credits['cast'];
    if (cast is! List) return fallback;

    final mapped = cast.whereType<Map<String, dynamic>>().take(12).map((actor) {
      return MovieCastMember(
        name: actor['name'] as String? ?? 'Unknown',
        character: actor['character'] as String? ?? '',
        photoUrl: _imageUrl(actor['profile_path'] as String?),
      );
    }).toList();

    return mapped.isEmpty ? fallback : mapped;
  }

  static List<TmdbReview> _reviews(Object? reviews, List<TmdbReview> fallback) {
    if (reviews is! Map<String, dynamic>) return fallback;
    final results = reviews['results'];
    if (results is! List) return fallback;

    final mapped = results.whereType<Map<String, dynamic>>().take(3).map((
      review,
    ) {
      final authorDetails = review['author_details'];
      final details = authorDetails is Map<String, dynamic>
          ? authorDetails
          : const <String, dynamic>{};

      return TmdbReview(
        username:
            details['username'] as String? ??
            review['author'] as String? ??
            'TMDB User',
        avatarUrl: _avatarUrl(details['avatar_path'] as String?),
        rating: ((details['rating'] as num?) ?? 0).toDouble(),
        text: review['content'] as String? ?? '',
        date: _date(review['created_at'] as String?),
        helpful: 0,
      );
    }).toList();

    return mapped.isEmpty ? fallback : mapped;
  }

  static String _avatarUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'https://image.tmdb.org/t/p/w185/default-avatar.png';
    }
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    if (normalized.startsWith('http')) return normalized;
    return '${ApiConstants.imageBaseUrl}/$normalized';
  }

  static String _yearFromDate(String? value, String fallback) {
    if (value == null || value.length < 4) return fallback;
    return value.substring(0, 4);
  }

  static String _duration(int? minutes, String fallback) {
    if (minutes == null || minutes <= 0) return fallback;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    return '${hours}h ${remainingMinutes}m';
  }

  static String _formatVotes(int? value, String fallback) {
    if (value == null) return fallback;
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  static String _date(String? value) {
    if (value == null || value.length < 10) return 'Unknown date';
    return value.substring(0, 10);
  }
}
