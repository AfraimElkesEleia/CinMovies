import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingState extends Equatable {
  const OnboardingState({this.pageIndex = 0});

  final int pageIndex;

  @override
  List<Object> get props => [pageIndex];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._preferences) : super(const OnboardingState());

  final LocalPreferencesService _preferences;

  void setPage(int index) => emit(OnboardingState(pageIndex: index));

  Future<void> markPassed() {
    return _preferences.setHasPassedOnboarding(true);
  }
}
