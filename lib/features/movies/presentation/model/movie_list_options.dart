enum MovieListStatus { initial, loading, loaded, failure }

enum MovieSortOption {
  rating('Rating'),
  title('A-Z'),
  newest('Newest');

  const MovieSortOption(this.label);

  final String label;
}
