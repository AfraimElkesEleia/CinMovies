import 'package:cinmovies_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:cinmovies_app/features/main/presentation/cubit/main_navigation_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blocked back navigation returns every non-home tab to home', () {
    final cubit = MainNavigationCubit();
    addTearDown(cubit.close);

    for (final tab in AppNavTab.values.where((tab) => tab != AppNavTab.home)) {
      cubit.selectTab(tab);
      cubit.handleBlockedBackNavigation();

      expect(cubit.state, AppNavTab.home);
    }
  });

  test('blocked back navigation keeps home selected', () {
    final cubit = MainNavigationCubit();
    addTearDown(cubit.close);

    cubit.handleBlockedBackNavigation();

    expect(cubit.state, AppNavTab.home);
  });
}
