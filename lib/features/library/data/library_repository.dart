import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/movies/data/movie_repository.dart';
import 'package:dartz/dartz.dart';

enum UserMovieListType {
  favorite('favorite'),
  watchlist('watchlist'),
  watched('watched'),
  downloaded('downloaded');

  const UserMovieListType(this.value);

  final String value;
}

class LibraryRepository {
  const LibraryRepository(
    this._database,
    this._movieRepository,
    this._cache, [
    this._errorMapper = defaultErrorMapper,
  ]);

  final SupabaseDatabaseService _database;
  final MovieRepository _movieRepository;
  final HiveCacheService _cache;
  final ErrorMapperRegistry _errorMapper;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<Either<Failure, bool>> contains(
    Movie movie,
    UserMovieListType type,
  ) async {
    try {
      final movieIdResult = await _movieRepository.cacheMovie(movie);
      return movieIdResult.fold(
        Left.new,
        (movieId) async {
          final row = await _database
              .from('user_movie_lists')
              .select('movie_id')
              .eq('user_id', _userId)
              .eq('movie_id', movieId)
              .eq('list_type', type.value)
              .maybeSingle();
          return Right(row != null);
        },
      );
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, void>> setListed(
    Movie movie,
    UserMovieListType type, {
    required bool listed,
  }) async {
    try {
      final movieIdResult = await _movieRepository.cacheMovie(movie);
      return movieIdResult.fold(
        Left.new,
        (movieId) async {
          if (listed) {
            await _database.from('user_movie_lists').upsert({
              'user_id': _userId,
              'movie_id': movieId,
              'list_type': type.value,
            });
          } else {
            await _database
                .from('user_movie_lists')
                .delete()
                .eq('user_id', _userId)
                .eq('movie_id', movieId)
                .eq('list_type', type.value);
          }
          return const Right(null);
        },
      );
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> movieRows(
    UserMovieListType type,
  ) async {
    try {
      final rows = await _database
          .from('user_movie_lists')
          .select('movies(*)')
          .eq('user_id', _userId)
          .eq('list_type', type.value)
          .order('added_at', ascending: false);

      final movieRows = rows
          .map<Map<String, dynamic>>(
            (row) => Map<String, dynamic>.from(row['movies'] as Map),
          )
          .toList();
      await _cache.cacheUserSnapshot('library_${type.value}', movieRows);
      return Right(movieRows);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, int>> count(UserMovieListType type) async {
    try {
      final rows = await _database
          .from('user_movie_lists')
          .select('movie_id')
          .eq('user_id', _userId)
          .eq('list_type', type.value);
      return Right(rows.length);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }
}

