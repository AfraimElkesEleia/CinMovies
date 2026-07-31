import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/preferences/domain/movie_genre_option.dart';

abstract class TmdbMovieMapper {
  static Movie fromJson(Map<String, dynamic> json) {
    final releaseDate = json['release_date'] as String?;
    final voteCount = (json['vote_count'] as num?)?.toInt();
    final runtime = ((json['runtime'] ?? json['runtime_minutes']) as num?)
        ?.toInt();

    return Movie(
      id: ((json['id'] ?? json['tmdb_id']) as num?)?.toInt().toString() ?? '',
      title:
          (json['title'] as String?) ??
          (json['original_title'] as String?) ??
          'Untitled Movie',
      imageAsset: _imageUrl(
        (json['poster_path'] as String?) ??
            (json['backdrop_path'] as String?) ??
            (json['image_asset'] as String?),
      ),
      genres: _genres(
        json['genres'] ?? json['genre_names'] ?? json['genre_ids'],
      ),
      rating: ((json['vote_average'] as num?) ?? 0).toDouble(),
      year: _yearFromDate(releaseDate),
      duration: _duration(runtime),
      ageRating: (json['age_rating'] as String?)?.trim().isNotEmpty == true
          ? (json['age_rating'] as String).trim()
          : 'NR',
      synopsis: (json['overview'] as String?)?.trim().isNotEmpty == true
          ? (json['overview'] as String).trim()
          : 'No synopsis available.',
      director: 'Unknown',
      votes: _formatVotes(voteCount),
      cast: const [],
      reviews: const [],
    );
  }

  static List<Movie> listFromResponse(Object? data) {
    if (data is! Map<String, dynamic>) return const [];
    final results = data['results'];
    if (results is! List) return const [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .where((movie) => movie.id.isNotEmpty)
        .toList();
  }

  static String _imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'assets/images/app_logo.png';
    }
    if (path.startsWith('http')) return path;
    return '${ApiConstants.imageBaseUrl}$path';
  }

  static String _yearFromDate(String? value) {
    if (value == null || value.length < 4) return 'N/A';
    return value.substring(0, 4);
  }

  static String _formatVotes(int? value) {
    if (value == null) return '0';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  static List<String> _genres(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map<String?>((genre) {
          if (genre is String) return genre.trim();
          if (genre is num) {
            return movieGenreNameFromTmdbId(genre.toInt());
          }
          if (genre is Map) return (genre['name'] as String?)?.trim();
          return null;
        })
        .whereType<String>()
        .where((genre) => genre.isNotEmpty)
        .toList();
  }

  static String _duration(int? minutes) {
    if (minutes == null || minutes <= 0) return 'N/A';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }
}
