class HomeMovieModel {
  const HomeMovieModel({
    required this.id,
    required this.title,
    required this.imageAsset,
    required this.genres,
    required this.rating,
    required this.year,
    required this.duration,
    required this.ageRating,
    required this.synopsis,
    required this.director,
    required this.votes,
    required this.availability,
    required this.cast,
    required this.reviews,
  });

  final String id;
  final String title;
  final String imageAsset;
  final List<String> genres;
  final double rating;
  final String year;
  final String duration;
  final String ageRating;
  final String synopsis;
  final String director;
  final String votes;
  final MovieAvailability availability;
  final List<MovieCastMember> cast;
  final List<MovieReview> reviews;
}

enum MovieAvailability { streaming, comingSoon, rental }

class MovieCastMember {
  const MovieCastMember({
    required this.name,
    required this.character,
    required this.photoUrl,
  });

  final String name;
  final String character;
  final String photoUrl;
}

class MovieReview {
  const MovieReview({
    required this.username,
    required this.avatarUrl,
    required this.rating,
    required this.text,
    required this.date,
    required this.helpful,
    this.spoiler = false,
  });

  final String username;
  final String avatarUrl;
  final double rating;
  final String text;
  final String date;
  final int helpful;
  final bool spoiler;
}
