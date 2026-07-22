import 'package:cinmovies_app/features/home/presentation/data/home_mock_data.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowseState extends Equatable {
  const BrowseState({this.activeGenre = 'All'});

  static const genres = ['All', 'Action', 'Adventure', 'Hero', 'Sci-Fi', 'Drama'];

  final String activeGenre;

  List<HomeMovieModel> get filteredMovies {
    if (activeGenre == 'All') return kHomeMovies;
    return kHomeMovies.where((movie) => movie.genres.contains(activeGenre)).toList();
  }

  @override
  List<Object> get props => [activeGenre];
}

class BrowseCubit extends Cubit<BrowseState> {
  BrowseCubit() : super(const BrowseState());

  void setGenre(String genre) => emit(BrowseState(activeGenre: genre));
}
