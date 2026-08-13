import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:dio/dio.dart';

abstract interface class SearchRepository {
  Future<Result<SearchMoviesPage>> searchMovies({
    required String query,
    required int page,
  });
}

final class TmdbSearchRepository implements SearchRepository {
  const TmdbSearchRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final ErrorMapper _errorMapper;

  @override
  Future<Result<SearchMoviesPage>> searchMovies({
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
      );

      return Success(SearchMoviesPage.fromJson(response.data));
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
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

  final List<Movie> movies;
  final int page;
  final int totalPages;
}
