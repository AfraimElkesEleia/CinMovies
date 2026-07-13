class HomeMovieModel {
  const HomeMovieModel({
    required this.title,
    required this.imageAsset,
    required this.genres,
    required this.rating,
    required this.year,
  });

  final String title;
  final String imageAsset;
  final List<String> genres;
  final double rating;
  final String year;
}
