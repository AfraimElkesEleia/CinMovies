import 'package:cinmovies_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainNavigationCubit extends Cubit<AppNavTab> {
  MainNavigationCubit() : super(AppNavTab.home);

  void selectTab(AppNavTab tab) => emit(tab);
}
