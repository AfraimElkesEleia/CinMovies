import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/tmdb_movie_mapper.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class MovieDetailsRepository {
  MovieDetailsRepository(this._dio, [this._errorMapper = defaultErrorMapper]);

  final Dio _dio;
  final ErrorMapperRegistry _errorMapper;
  final Map<String, MovieDetailsResult> _detailsCache = {};

  Future<Either<Failure, MovieDetailsResult>> fetchMovieDetails(
    Movie seed,
  ) async {
    final cached = _detailsCache[seed.id];
    if (cached != null) return Right(cached);

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.movieDetails}/${seed.id}',
        queryParameters: const {
          'language': 'en-US',
          'append_to_response': 'credits,reviews,similar,videos',
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${EnvConfig.tmdbAccessToken}'},
        ),
      );

      final result = MovieDetailsResult.fromJson(response.data, seed);
      _detailsCache[seed.id] = result;
      return Right(result);
    } catch (error) {
      return Left(_errorMapper.map(error));
    }
  }
}

class MovieDetailsResult {
  const MovieDetailsResult({required this.movie, required this.similarMovies});

  factory MovieDetailsResult.fromJson(
    Map<String, dynamic>? json,
    Movie seed,
  ) {
    if (json == null) {
      return MovieDetailsResult(movie: seed, similarMovies: const []);
    }

    return MovieDetailsResult(
      movie: _movieFromJson(json, seed),
      similarMovies: TmdbMovieMapper.listFromResponse(json['similar']),
    );
  }

  final Movie movie;
  final List<Movie> similarMovies;

  static Movie _movieFromJson(
    Map<String, dynamic> json,
    Movie seed,
  ) {
    final voteCount = (json['vote_count'] as num?)?.toInt();
    final runtime = (json['runtime'] as num?)?.toInt();

    return Movie(
      id: (json['id'] as num?)?.toInt().toString() ?? seed.id,
      title:
          (json['title'] as String?) ??
          (json['original_title'] as String?) ??
          seed.title,
      imageAsset: _imageUrl(
        (json['backdrop_path'] as String?) ??
            (json['poster_path'] as String?) ??
            seed.imageAsset,
      ),
      genres: _genres(json['genres'], seed.genres),
      rating: ((json['vote_average'] as num?) ?? seed.rating).toDouble(),
      year: _yearFromDate(json['release_date'] as String?, seed.year),
      duration: _duration(runtime, seed.duration),
      ageRating: seed.ageRating,
      synopsis: (json['overview'] as String?)?.trim().isNotEmpty == true
          ? (json['overview'] as String).trim()
          : seed.synopsis,
      director: _director(json['credits'], seed.director),
      votes: _formatVotes(voteCount, seed.votes),
      availability: seed.availability,
      cast: _cast(json['credits'], seed.cast),
      reviews: _reviews(json['reviews'], seed.reviews),
    );
  }

  static String _imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'assets/images/movie_ex1.jpg';
    }
    if (path.startsWith('http') || path.startsWith('assets/')) return path;
    return '${ApiConstants.imageBaseUrl}$path';
  }

  static List<String> _genres(Object? value, List<String> fallback) {
    if (value is! List) return fallback;
    final genres = value
        .whereType<Map<String, dynamic>>()
        .map((genre) => genre['name'] as String?)
        .whereType<String>()
        .toList();
    return genres.isEmpty ? fallback : genres;
  }

  static String _director(Object? credits, String fallback) {
    if (credits is! Map<String, dynamic>) return fallback;
    final crew = credits['crew'];
    if (crew is! List) return fallback;
    for (final member in crew.whereType<Map<String, dynamic>>()) {
      if (member['job'] == 'Director') {
        return member['name'] as String? ?? fallback;
      }
    }
    return fallback;
  }

  static List<MovieCastMember> _cast(
    Object? credits,
    List<MovieCastMember> fallback,
  ) {
    if (credits is! Map<String, dynamic>) return fallback;
    final cast = credits['cast'];
    if (cast is! List) return fallback;

    final mapped = cast.whereType<Map<String, dynamic>>().take(12).map((actor) {
      return MovieCastMember(
        name: actor['name'] as String? ?? 'Unknown',
        character: actor['character'] as String? ?? '',
        photoUrl: _imageUrl(actor['profile_path'] as String?),
      );
    }).toList();

    return mapped.isEmpty ? fallback : mapped;
  }

  static List<MovieReview> _reviews(
    Object? reviews,
    List<MovieReview> fallback,
  ) {
    if (reviews is! Map<String, dynamic>) return fallback;
    final results = reviews['results'];
    if (results is! List) return fallback;

    final mapped = results.whereType<Map<String, dynamic>>().take(3).map((
      review,
    ) {
      final authorDetails = review['author_details'];
      final details = authorDetails is Map<String, dynamic>
          ? authorDetails
          : const <String, dynamic>{};

      return MovieReview(
        username:
            details['username'] as String? ??
            review['author'] as String? ??
            'TMDB User',
        avatarUrl: _avatarUrl(details['avatar_path'] as String?),
        rating: ((details['rating'] as num?) ?? 0).toDouble(),
        text: review['content'] as String? ?? '',
        date: _date(review['created_at'] as String?),
        helpful: 0,
      );
    }).toList();

    return mapped.isEmpty ? fallback : mapped;
  }

  static String _avatarUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'https://image.tmdb.org/t/p/w185/default-avatar.png';
    }
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    if (normalized.startsWith('http')) return normalized;
    return '${ApiConstants.imageBaseUrl}/$normalized';
  }

  static String _yearFromDate(String? value, String fallback) {
    if (value == null || value.length < 4) return fallback;
    return value.substring(0, 4);
  }

  static String _duration(int? minutes, String fallback) {
    if (minutes == null || minutes <= 0) return fallback;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    return '${hours}h ${remainingMinutes}m';
  }

  static String _formatVotes(int? value, String fallback) {
    if (value == null) return fallback;
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  static String _date(String? value) {
    if (value == null || value.length < 10) return 'Unknown date';
    return value.substring(0, 10);
  }
}
