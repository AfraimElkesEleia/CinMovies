import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBootstrapState extends Equatable {
  const AppBootstrapState({this.initialRoute = Routes.onBoarding});

  final String initialRoute;

  @override
  List<Object> get props => [initialRoute];
}

class AppBootstrapCubit extends Cubit<AppBootstrapState> {
  AppBootstrapCubit(this._authRepository, this._preferences)
      : super(const AppBootstrapState());

  final AuthRepository _authRepository;
  final LocalPreferencesService _preferences;

  Future<String> resolveInitialRoute() async {
    final route = !_preferences.hasPassedOnboarding
        ? Routes.onBoarding
        : _authRepository.currentUser == null
            ? Routes.login
            : Routes.home;
    emit(AppBootstrapState(initialRoute: route));
    return route;
  }
}
