import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';
import 'package:dartz/dartz.dart';

class MovieRepository {
  const MovieRepository(
    this._database,
    this._cache, [
    this._errorMapper = defaultErrorMapper,
  ]);

  final SupabaseDatabaseService _database;
  final HiveCacheService _cache;
  final ErrorMapperRegistry _errorMapper;

  Future<Either<Failure, String>> cacheMovie(HomeMovieModel movie) async {
    try {
      final response = await _database.rpc(
        'cache_movie',
        params: {
          'p_tmdb_id': tmdbIdForMovie(movie),
          'p_title': movie.title,
          'p_original_title': movie.title,
          'p_overview': movie.synopsis,
          'p_poster_path': movie.imageAsset,
          'p_backdrop_path': movie.imageAsset,
          'p_release_date': _releaseDate(movie.year),
          'p_runtime_minutes': _runtimeMinutes(movie.duration),
          'p_age_rating': movie.ageRating,
          'p_vote_average': movie.rating,
          'p_vote_count': _voteCount(movie.votes),
          'p_popularity': null,
          'p_genre_names': movie.genres,
        },
      );

      final movieId = response as String;
      await _cache.cacheMovie(movieId, {
        'id': movieId,
        'tmdb_id': tmdbIdForMovie(movie),
        'title': movie.title,
        'poster_path': movie.imageAsset,
        'release_date': _releaseDate(movie.year),
        'runtime_minutes': _runtimeMinutes(movie.duration),
      });
      return Right(movieId);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  int tmdbIdForMovie(HomeMovieModel movie) {
    final numericId = int.tryParse(movie.id);
    if (numericId != null && numericId > 0) return numericId;

    var hash = 0;
    for (final codeUnit in movie.id.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash == 0 ? 1 : hash;
  }

  String? _releaseDate(String year) {
    final parsedYear = int.tryParse(year);
    if (parsedYear == null) return null;
    return '$parsedYear-01-01';
  }

  int? _runtimeMinutes(String duration) {
    final hours = RegExp(r'(\d+)h').firstMatch(duration);
    final minutes = RegExp(r'(\d+)m').firstMatch(duration);
    final total =
        (int.tryParse(hours?.group(1) ?? '') ?? 0) * 60 +
        (int.tryParse(minutes?.group(1) ?? '') ?? 0);
    return total == 0 ? null : total;
  }

  int? _voteCount(String votes) {
    final normalized = votes.trim().toUpperCase();
    final value = double.tryParse(normalized.replaceAll('K', ''));
    if (value == null) return null;
    return normalized.endsWith('K') ? (value * 1000).round() : value.round();
  }
}

