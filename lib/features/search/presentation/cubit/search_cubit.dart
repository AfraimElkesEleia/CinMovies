import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:cinmovies_app/features/search/presentation/data/search_mock_data.dart';
import 'package:cinmovies_app/features/search/presentation/utils/search_movie_filter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.recentSearches = const [],
  });

  final String query;
  final List<String> recentSearches;

  bool get hasQuery => query.trim().isNotEmpty;

  List<HomeMovieModel> get results {
    return SearchMovieFilter.byQuery(
      movies: SearchMockData.movies,
      query: query,
    );
  }

  SearchState copyWith({String? query, List<String>? recentSearches}) {
    return SearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  @override
  List<Object> get props => [query, recentSearches];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._cache)
      : super(SearchState(recentSearches: _cache.getRecentSearches()));

  final HiveCacheService _cache;

  void setQuery(String value) => emit(state.copyWith(query: value));

  void clear() => emit(state.copyWith(query: ''));

  Future<void> submit(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    await _cache.saveRecentSearch(query);
    emit(
      state.copyWith(
        query: query,
        recentSearches: _cache.getRecentSearches(),
      ),
    );
  }
}
