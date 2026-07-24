import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HomeRepository {
  const HomeRepository(this._dio, [this._errorMapper = defaultErrorMapper]);

  final Dio _dio;
  final ErrorMapperRegistry _errorMapper;

  Future<Either<Failure, HomeMoviesResult>> fetchHomeMovies() async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>(
          ApiConstants.popularMovies,
          queryParameters: _queryParameters(),
          options: _authOptions(),
        ),
        _dio.get<Map<String, dynamic>>(
          ApiConstants.upcomingMovies,
          queryParameters: _queryParameters(),
          options: _authOptions(),
        ),
      ]);

      return Right(
        HomeMoviesResult(
          popularMovies: TmdbMovieMapper.listFromResponse(responses[0].data),
          upcomingMovies: TmdbMovieMapper.listFromResponse(responses[1].data),
        ),
      );
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Map<String, Object> _queryParameters() {
    return {'language': 'en-US', 'page': 1};
  }

  Options _authOptions() {
    return Options(
      headers: {'Authorization': 'Bearer ${EnvConfig.tmdbAccessToken}'},
    );
  }
}

class HomeMoviesResult {
  const HomeMoviesResult({
    required this.popularMovies,
    required this.upcomingMovies,
  });

  final List<Movie> popularMovies;
  final List<Movie> upcomingMovies;
}
