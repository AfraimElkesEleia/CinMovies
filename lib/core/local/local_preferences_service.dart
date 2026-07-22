import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferencesService {
  const LocalPreferencesService(this._preferences);

  static const _hasPassedOnboardingKey = 'has_passed_onboarding';

  final SharedPreferences _preferences;

  bool get hasPassedOnboarding {
    return _preferences.getBool(_hasPassedOnboardingKey) ?? false;
  }

  Future<void> setHasPassedOnboarding(bool value) {
    return _preferences.setBool(_hasPassedOnboardingKey, value);
  }
}
