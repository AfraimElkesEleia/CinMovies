import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/movies/data/movie_repository.dart';

enum UserMovieListType {
  favorite('favorite'),
  watchlist('watchlist'),
  watched('watched'),
  downloaded('downloaded');

  const UserMovieListType(this.value);

  final String value;
}

class LibraryRepository {
  const LibraryRepository(this._database, this._movieRepository, this._cache);

  final SupabaseDatabaseService _database;
  final MovieRepository _movieRepository;
  final HiveCacheService _cache;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<bool> contains(HomeMovieModel movie, UserMovieListType type) async {
    final movieId = await _movieRepository.cacheMovie(movie);
    final row = await _database
        .from('user_movie_lists')
        .select('movie_id')
        .eq('user_id', _userId)
        .eq('movie_id', movieId)
        .eq('list_type', type.value)
        .maybeSingle();
    return row != null;
  }

  Future<void> setListed(
    HomeMovieModel movie,
    UserMovieListType type, {
    required bool listed,
  }) async {
    final movieId = await _movieRepository.cacheMovie(movie);
    if (listed) {
      await _database.from('user_movie_lists').upsert({
        'user_id': _userId,
        'movie_id': movieId,
        'list_type': type.value,
      });
      return;
    }

    await _database
        .from('user_movie_lists')
        .delete()
        .eq('user_id', _userId)
        .eq('movie_id', movieId)
        .eq('list_type', type.value);
  }

  Future<List<Map<String, dynamic>>> movieRows(UserMovieListType type) async {
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
    return movieRows;
  }

  Future<int> count(UserMovieListType type) async {
    final rows = await _database
        .from('user_movie_lists')
        .select('movie_id')
        .eq('user_id', _userId)
        .eq('list_type', type.value);
    return rows.length;
  }
}
