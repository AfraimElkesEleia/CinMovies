class MovieGenreOption {
  final String genre;
  final String emoji;
  final int tmdbId;
  final String tmdbName;

  const MovieGenreOption({
    required this.genre,
    required this.emoji,
    required this.tmdbId,
    required this.tmdbName,
  });
}

const List<MovieGenreOption> movieGenreOptions = [
  MovieGenreOption(
    genre: 'Action',
    emoji: '⚡',
    tmdbId: 28,
    tmdbName: 'Action',
  ),
  MovieGenreOption(
    genre: 'Adventure',
    emoji: '🧭',
    tmdbId: 12,
    tmdbName: 'Adventure',
  ),
  MovieGenreOption(
    genre: 'Comedy',
    emoji: '😂',
    tmdbId: 35,
    tmdbName: 'Comedy',
  ),
  MovieGenreOption(
    genre: 'Drama',
    emoji: '🎭',
    tmdbId: 18,
    tmdbName: 'Drama',
  ),
  MovieGenreOption(
    genre: 'Horror',
    emoji: '👻',
    tmdbId: 27,
    tmdbName: 'Horror',
  ),
  MovieGenreOption(
    genre: 'Animation',
    emoji: '✨',
    tmdbId: 16,
    tmdbName: 'Animation',
  ),
  MovieGenreOption(
    genre: 'Sci-Fi',
    emoji: '🚀',
    tmdbId: 878,
    tmdbName: 'Science Fiction',
  ),
  MovieGenreOption(
    genre: 'Romance',
    emoji: '❤️',
    tmdbId: 10749,
    tmdbName: 'Romance',
  ),
  MovieGenreOption(
    genre: 'Thriller',
    emoji: '🔪',
    tmdbId: 53,
    tmdbName: 'Thriller',
  ),
  MovieGenreOption(
    genre: 'Documentary',
    emoji: '🎬',
    tmdbId: 99,
    tmdbName: 'Documentary',
  ),
  MovieGenreOption(
    genre: 'Crime',
    emoji: '🕵️',
    tmdbId: 80,
    tmdbName: 'Crime',
  ),
  MovieGenreOption(
    genre: 'Fantasy',
    emoji: '🪄',
    tmdbId: 14,
    tmdbName: 'Fantasy',
  ),
];

final Map<String, MovieGenreOption> _movieGenreOptionsByName = {
  for (final option in movieGenreOptions) ...{
    _normalizedGenreName(option.genre): option,
    _normalizedGenreName(option.tmdbName): option,
  },
};

List<int> normalizeFavoriteGenreIds(Iterable<String> genreNames) {
  final ids = genreNames
      .map((name) => _movieGenreOptionsByName[_normalizedGenreName(name)]?.tmdbId)
      .whereType<int>()
      .toSet()
      .toList()
    ..sort();
  return ids;
}

String? movieGenreNameFromTmdbId(int id) {
  for (final option in movieGenreOptions) {
    if (option.tmdbId == id) return option.genre;
  }
  return null;
}

String _normalizedGenreName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
