import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/constants/api_constants.dart';
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

  Future<Either<Failure, List<Movie>>> movies(UserMovieListType type) async {
    final result = await movieRows(type);
    return result.map(
      (rows) => rows
          .map(movieFromRow)
          .where((movie) => movie.id.trim().isNotEmpty)
          .toList(),
    );
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

  static Movie movieFromRow(Map<String, dynamic> row) {
    final releaseDate = row['release_date'] as String?;
    final runtimeMinutes = row['runtime_minutes'] as int?;
    final voteCount = row['vote_count'] as int?;

    return Movie(
      id:
          (row['tmdb_id'] as num?)?.toInt().toString() ??
          (row['id'] as String? ?? ''),
      title:
          (row['title'] as String?) ??
          (row['original_title'] as String?) ??
          'Untitled Movie',
      imageAsset: _imageUrl(
        (row['poster_path'] as String?) ?? (row['backdrop_path'] as String?),
      ),
      genres: const [],
      rating: ((row['vote_average'] as num?) ?? 0).toDouble(),
      year: _yearFromDate(releaseDate),
      duration: _duration(runtimeMinutes),
      ageRating: row['age_rating'] as String? ?? 'NR',
      synopsis: (row['overview'] as String?)?.trim().isNotEmpty == true
          ? (row['overview'] as String).trim()
          : 'No synopsis available.',
      director: 'Unknown',
      votes: _formatVotes(voteCount),
      availability: MovieAvailability.streaming,
      cast: const [],
      reviews: const [],
    );
  }

  static String _imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'assets/images/app_logo.png';
    }
    if (path.startsWith('http')) return path;
    return '${ApiConstants.imageBaseUrl}$path';
  }

  static String _yearFromDate(String? value) {
    if (value == null || value.length < 4) return 'N/A';
    return value.substring(0, 4);
  }

  static String _duration(int? minutes) {
    if (minutes == null || minutes <= 0) return 'N/A';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  static String _formatVotes(int? value) {
    if (value == null) return '0';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

