import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class SearchRepository {
  const SearchRepository(this._dio, [this._errorMapper = defaultErrorMapper]);

  final Dio _dio;
  final ErrorMapperRegistry _errorMapper;

  Future<Either<Failure, SearchMoviesPage>> searchMovies({
    required String query,
    required int page,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.searchMovies,
        queryParameters: {
          'query': query,
          'page': page,
          'language': 'en-US',
          'include_adult': false,
        },
        options: _authOptions(),
      );

      return Right(SearchMoviesPage.fromJson(response.data));
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Options _authOptions() {
    return Options(
      headers: {'Authorization': 'Bearer ${EnvConfig.tmdbAccessToken}'},
    );
  }
}

class SearchMoviesPage {
  const SearchMoviesPage({
    required this.movies,
    required this.page,
    required this.totalPages,
  });

  factory SearchMoviesPage.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      return const SearchMoviesPage(movies: [], page: 1, totalPages: 1);
    }

    return SearchMoviesPage(
      movies: TmdbMovieMapper.listFromResponse(data),
      page: ((data['page'] as num?) ?? 1).toInt(),
      totalPages: ((data['total_pages'] as num?) ?? 1).toInt(),
    );
  }

  final List<HomeMovieModel> movies;
  final int page;
  final int totalPages;
}
