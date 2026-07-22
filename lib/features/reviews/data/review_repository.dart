import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/movies/data/movie_repository.dart';

class ReviewRepository {
  const ReviewRepository(this._database, this._movieRepository);

  final SupabaseDatabaseService _database;
  final MovieRepository _movieRepository;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<void> upsertReview({
    required HomeMovieModel movie,
    required double rating,
    String? title,
    String? body,
    bool spoiler = false,
  }) async {
    final movieId = await _movieRepository.cacheMovie(movie);
    await _database.from('user_reviews').upsert({
      'user_id': _userId,
      'movie_id': movieId,
      'rating': rating,
      'title': title,
      'body': body,
      'spoiler': spoiler,
    }, onConflict: 'user_id,movie_id');
  }

  Future<List<Map<String, dynamic>>> reviewsForMovie(HomeMovieModel movie) async {
    final movieId = await _movieRepository.cacheMovie(movie);
    final rows = await _database
        .from('user_reviews')
        .select('*, profiles(username, full_name, avatar_url)')
        .eq('movie_id', movieId)
        .order('created_at', ascending: false);

    return rows.map<Map<String, dynamic>>(Map<String, dynamic>.from).toList();
  }
}
