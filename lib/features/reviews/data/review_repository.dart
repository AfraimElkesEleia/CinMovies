import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/movies/data/movie_repository.dart';
import 'package:dartz/dartz.dart';

class ReviewRepository {
  const ReviewRepository(
    this._database,
    this._movieRepository, [
    this._errorMapper = defaultErrorMapper,
  ]);

  final SupabaseDatabaseService _database;
  final MovieRepository _movieRepository;
  final ErrorMapperRegistry _errorMapper;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<Either<Failure, void>> upsertReview({
    required HomeMovieModel movie,
    required double rating,
    String? title,
    String? body,
    bool spoiler = false,
  }) async {
    try {
      final movieIdResult = await _movieRepository.cacheMovie(movie);
      return movieIdResult.fold(
        Left.new,
        (movieId) async {
          await _database.from('user_reviews').upsert({
            'user_id': _userId,
            'movie_id': movieId,
            'rating': rating,
            'title': title,
            'body': body,
            'spoiler': spoiler,
          }, onConflict: 'user_id,movie_id');
          return const Right(null);
        },
      );
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> reviewsForMovie(
    HomeMovieModel movie,
  ) async {
    try {
      final movieIdResult = await _movieRepository.cacheMovie(movie);
      return movieIdResult.fold(
        Left.new,
        (movieId) async {
          final rows = await _database
              .from('user_reviews')
              .select('*, profiles(username, full_name, avatar_url)')
              .eq('movie_id', movieId)
              .order('created_at', ascending: false);
          return Right(
            rows.map<Map<String, dynamic>>(Map<String, dynamic>.from).toList(),
          );
        },
      );
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }
}

