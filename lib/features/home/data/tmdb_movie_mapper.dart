import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/data/model/home_movie_model.dart';

abstract class TmdbMovieMapper {
  static HomeMovieModel fromJson(Map<String, dynamic> json) {
    final releaseDate = json['release_date'] as String?;
    final voteCount = json['vote_count'] as int?;

    return HomeMovieModel(
      id: (json['id'] as num?)?.toInt().toString() ?? '',
      title:
          (json['title'] as String?) ??
          (json['original_title'] as String?) ??
          'Untitled Movie',
      imageAsset: _imageUrl(
        (json['poster_path'] as String?) ?? (json['backdrop_path'] as String?),
      ),
      genres: const [],
      rating: ((json['vote_average'] as num?) ?? 0).toDouble(),
      year: _yearFromDate(releaseDate),
      duration: 'N/A',
      ageRating: 'NR',
      synopsis: (json['overview'] as String?)?.trim().isNotEmpty == true
          ? (json['overview'] as String).trim()
          : 'No synopsis available.',
      director: 'Unknown',
      votes: _formatVotes(voteCount),
      availability: MovieAvailability.streaming,
      cast: kMovieCast,
      reviews: kMovieReviews,
    );
  }

  static List<HomeMovieModel> listFromResponse(Object? data) {
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
      return 'assets/images/movie_ex1.jpg';
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
}
