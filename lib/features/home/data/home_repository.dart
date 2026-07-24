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

  Future<Either<Failure, MovieSectionPage>> fetchMovieSection({
    required HomeMovieSection section,
    required int page,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        section.path,
        queryParameters: _queryParameters(page),
        options: _authOptions(),
      );

      return Right(MovieSectionPage.fromJson(response.data));
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Map<String, Object> _queryParameters([int page = 1]) {
    return {'language': 'en-US', 'page': page};
  }

  Options _authOptions() {
    return Options(
      headers: {'Authorization': 'Bearer ${EnvConfig.tmdbAccessToken}'},
    );
  }
}

enum HomeMovieSection {
  popular('Trending Now', ApiConstants.popularMovies),
  upcoming('New Releases', ApiConstants.upcomingMovies);

  const HomeMovieSection(this.title, this.path);

  final String title;
  final String path;
}

class HomeMoviesResult {
  const HomeMoviesResult({
    required this.popularMovies,
    required this.upcomingMovies,
  });

  final List<Movie> popularMovies;
  final List<Movie> upcomingMovies;
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
