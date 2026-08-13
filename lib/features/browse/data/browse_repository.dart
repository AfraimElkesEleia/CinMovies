import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:dio/dio.dart';

abstract interface class BrowseRepository {
  Future<Result<List<BrowseGenre>>> fetchGenres();

  Future<Result<BrowseMoviesPage>> fetchMovies({
    required int page,
    BrowseGenre genre = BrowseGenre.all,
  });
}

final class TmdbBrowseRepository implements BrowseRepository {
  const TmdbBrowseRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final ErrorMapper _errorMapper;

  @override
  Future<Result<List<BrowseGenre>>> fetchGenres() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.movieGenres,
        queryParameters: const {'language': 'en-US'},
      );

      final genres = _genresFromResponse(response.data);
      return Success([BrowseGenre.all, ...genres]);
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
  }

  @override
  Future<Result<BrowseMoviesPage>> fetchMovies({
    required int page,
    BrowseGenre genre = BrowseGenre.all,
  }) async {
    try {
      final queryParameters = <String, Object>{
        'language': 'en-US',
        'page': page,
        'sort_by': 'popularity.desc',
      };

      if (!genre.isAll && genre.id != null) {
        queryParameters['with_genres'] = genre.id!;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.discoverMovies,
        queryParameters: queryParameters,
      );

      return Success(BrowseMoviesPage.fromJson(response.data));
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
  }

  List<BrowseGenre> _genresFromResponse(Object? data) {
    if (data is! Map<String, dynamic>) return const [];
    final genres = data['genres'];
    if (genres is! List) return const [];

    return genres
        .whereType<Map<String, dynamic>>()
        .map((json) {
          return BrowseGenre(
            id: (json['id'] as num?)?.toInt(),
            name: (json['name'] as String?) ?? 'Unknown',
          );
        })
        .where((genre) => genre.id != null)
        .toList();
  }
}

class BrowseMoviesPage {
  const BrowseMoviesPage({
    required this.movies,
    required this.page,
    required this.totalPages,
  });

  factory BrowseMoviesPage.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      return const BrowseMoviesPage(movies: [], page: 1, totalPages: 1);
    }

    return BrowseMoviesPage(
      movies: TmdbMovieMapper.listFromResponse(data),
      page: ((data['page'] as num?) ?? 1).toInt(),
      totalPages: ((data['total_pages'] as num?) ?? 1).toInt(),
    );
  }

  final List<Movie> movies;
  final int page;
  final int totalPages;
}
