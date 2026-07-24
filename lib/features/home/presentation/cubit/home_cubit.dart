import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    required this.popularMovies,
    required this.upcomingMovies,
    this.failure,
  });

  const HomeState.initial()
    : status = HomeStatus.initial,
      popularMovies = const [],
      upcomingMovies = const [],
      failure = null;

  final HomeStatus status;
  final List<Movie> popularMovies;
  final List<Movie> upcomingMovies;
  final Failure? failure;

  List<Movie> get carouselMovies => popularMovies.take(5).toList();

  HomeState copyWith({
    HomeStatus? status,
    List<Movie>? popularMovies,
    List<Movie>? upcomingMovies,
    Failure? failure,
  }) {
    return HomeState(
      status: status ?? this.status,
      popularMovies: popularMovies ?? this.popularMovies,
      upcomingMovies: upcomingMovies ?? this.upcomingMovies,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, popularMovies, upcomingMovies, failure];
}

enum HomeStatus { initial, loading, loaded, failure }

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeState.initial());

  final HomeRepository _repository;

  Future<void> loadMovies() async {
    emit(state.copyWith(status: HomeStatus.loading, failure: null));

    final result = await _repository.fetchHomeMovies();
    result.fold(
      (failure) => emit(
        HomeState(
          status: HomeStatus.failure,
          popularMovies: state.popularMovies,
          upcomingMovies: state.upcomingMovies,
          failure: failure,
        ),
      ),
      (movies) => emit(
        HomeState(
          status: HomeStatus.loaded,
          popularMovies: movies.popularMovies,
          upcomingMovies: movies.upcomingMovies,
        ),
      ),
    );
  }
}
