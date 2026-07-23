import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/browse/data/browse_genre.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class BrowseRepository {
  const BrowseRepository(this._dio, [this._errorMapper = defaultErrorMapper]);

  final Dio _dio;
  final ErrorMapperRegistry _errorMapper;

  Future<Either<Failure, List<BrowseGenre>>> fetchGenres() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.movieGenres,
        queryParameters: const {'language': 'en-US'},
        options: _authOptions(),
      );

      final genres = _genresFromResponse(response.data);
      return Right([BrowseGenre.all, ...genres]);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  Future<Either<Failure, BrowseMoviesPage>> fetchMovies({
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
        options: _authOptions(),
      );

      return Right(BrowseMoviesPage.fromJson(response.data));
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }

  List<BrowseGenre> _genresFromResponse(Object? data) {
    if (data is! Map<String, dynamic>) return const [];
    final genres = data['genres'];
    if (genres is! List) return const [];

    return genres.whereType<Map<String, dynamic>>().map((json) {
      return BrowseGenre(
        id: (json['id'] as num?)?.toInt(),
        name: (json['name'] as String?) ?? 'Unknown',
      );
    }).where((genre) => genre.id != null).toList();
  }

  Options _authOptions() {
    return Options(
      headers: {'Authorization': 'Bearer ${EnvConfig.tmdbAccessToken}'},
    );
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

  final List<HomeMovieModel> movies;
  final int page;
  final int totalPages;
}
