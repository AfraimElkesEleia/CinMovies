import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';

abstract final class MovieCacheCodec {
  static Map<String, dynamic> encode(Movie movie) {
    return {
      'id': movie.id,
      'title': movie.title,
      'image_asset': movie.imageAsset,
      'genres': movie.genres,
      'rating': movie.rating,
      'year': movie.year,
      'duration': movie.duration,
      'age_rating': movie.ageRating,
      'synopsis': movie.synopsis,
      'director': movie.director,
      'votes': movie.votes,
      'cast': [
        for (final member in movie.cast)
          {
            'name': member.name,
            'character': member.character,
            'photo_url': member.photoUrl,
          },
      ],
      'reviews': [
        for (final review in movie.reviews)
          {
            'username': review.username,
            'avatar_url': review.avatarUrl,
            'rating': review.rating,
            'text': review.text,
            'date': review.date,
            'helpful': review.helpful,
            'spoiler': review.spoiler,
          },
      ],
    };
  }

  static Movie? decode(Object? value) {
    final json = _map(value);
    if (json == null) return null;

    final id = _string(json['id']);
    final title = _string(json['title']);
    if (id == null || id.isEmpty || title == null || title.isEmpty) return null;

    return Movie(
      id: id,
      title: title,
      imageAsset: _string(json['image_asset']) ?? 'assets/images/app_logo.png',
      genres: _strings(json['genres']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      year: _string(json['year']) ?? 'N/A',
      duration: _string(json['duration']) ?? 'N/A',
      ageRating: _string(json['age_rating']) ?? 'NR',
      synopsis:
          _string(json['synopsis']) ?? 'No synopsis available.',
      director: _string(json['director']) ?? 'Unknown',
      votes: _string(json['votes']) ?? '0',
      cast: _cast(json['cast']),
      reviews: _reviews(json['reviews']),
    );
  }

  static List<Movie> decodeList(Object? value) {
    if (value is! Iterable) return const [];
    return value.map(decode).whereType<Movie>().toList();
  }

  static List<MovieCastMember> _cast(Object? value) {
    if (value is! Iterable) return const [];
    return value.map(_map).whereType<Map<String, dynamic>>().map((json) {
      return MovieCastMember(
        name: _string(json['name']) ?? 'Unknown',
        character: _string(json['character']) ?? '',
        photoUrl:
            _string(json['photo_url']) ?? 'assets/images/app_logo.png',
      );
    }).toList();
  }

  static List<TmdbReview> _reviews(Object? value) {
    if (value is! Iterable) return const [];
    return value.map(_map).whereType<Map<String, dynamic>>().map((json) {
      return TmdbReview(
        username: _string(json['username']) ?? 'TMDB User',
        avatarUrl:
            _string(json['avatar_url']) ?? 'assets/images/app_logo.png',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        text: _string(json['text']) ?? '',
        date: _string(json['date']) ?? 'Unknown date',
        helpful: (json['helpful'] as num?)?.toInt() ?? 0,
        spoiler: json['spoiler'] == true,
      );
    }).toList();
  }

  static List<String> _strings(Object? value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().toList();
  }

  static String? _string(Object? value) {
    if (value is String) return value;
    if (value is num) return value.toString();
    return null;
  }

  static Map<String, dynamic>? _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
