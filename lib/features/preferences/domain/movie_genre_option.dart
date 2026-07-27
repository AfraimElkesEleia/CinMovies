class MovieGenreOption {
  final String genre;
  final String emoji;

  const MovieGenreOption({required this.genre, required this.emoji});
}

const List<MovieGenreOption> movieGenreOptions = [
  MovieGenreOption(genre: 'Action', emoji: '⚡'),
  MovieGenreOption(genre: 'Adventure', emoji: '🧭'),
  MovieGenreOption(genre: 'Comedy', emoji: '😂'),
  MovieGenreOption(genre: 'Drama', emoji: '🎭'),
  MovieGenreOption(genre: 'Horror', emoji: '👻'),
  MovieGenreOption(genre: 'Animation', emoji: '✨'),
  MovieGenreOption(genre: 'Sci-Fi', emoji: '🚀'),
  MovieGenreOption(genre: 'Romance', emoji: '❤️'),
  MovieGenreOption(genre: 'Thriller', emoji: '🔪'),
  MovieGenreOption(genre: 'Documentary', emoji: '🎬'),
  MovieGenreOption(genre: 'Crime', emoji: '🕵️'),
  MovieGenreOption(genre: 'Fantasy', emoji: '🪄'),
];
