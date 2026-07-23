import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/features/ai/data/ai_history_repository.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:cinmovies_app/features/browse/data/browse_repository.dart';
import 'package:cinmovies_app/features/browse/presentation/cubit/browse_cubit.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:cinmovies_app/features/main/presentation/cubit/main_navigation_cubit.dart';
import 'package:cinmovies_app/features/movies/data/movie_repository.dart';
import 'package:cinmovies_app/features/onboarding_screen/data/preference_repository.dart';
import 'package:cinmovies_app/features/onboarding_screen/presentation/cubit/onboarding_cubit.dart';
import 'package:cinmovies_app/features/onboarding_screen/presentation/cubit/preference_cubit.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:cinmovies_app/core/network/dio_client.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> initDependencies({
  required HiveCacheService hiveCacheService,
  required SharedPreferences sharedPreferences,
}) async {
  sl.registerLazySingleton<Dio>(DioClient.create);
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<SupabaseDatabaseService>(
    () => SupabaseDatabaseService(sl()),
  );
  sl.registerLazySingleton<SupabaseStorageService>(
    () => SupabaseStorageService(sl()),
  );
  sl.registerLazySingleton<HiveCacheService>(() => hiveCacheService);
  sl.registerLazySingleton<LocalPreferencesService>(
    () => LocalPreferencesService(sharedPreferences),
  );
  sl.registerLazySingleton<ErrorMapperRegistry>(() => defaultErrorMapper);
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<HomeRepository>(() => HomeRepository(sl(), sl()));
  sl.registerLazySingleton<BrowseRepository>(() => BrowseRepository(sl(), sl()));
  sl.registerLazySingleton<MovieRepository>(
    () => MovieRepository(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<LibraryRepository>(
    () => LibraryRepository(sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepository(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<PreferenceRepository>(
    () => PreferenceRepository(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<AiHistoryRepository>(() => AiHistoryRepository(sl()));

  sl.registerFactory<AuthCubit>(() => AuthCubit(sl(), sl()));
  sl.registerFactory<MainNavigationCubit>(MainNavigationCubit.new);
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl()));
  sl.registerFactory<BrowseCubit>(() => BrowseCubit(sl()));
  sl.registerFactory<LibraryCubit>(() => LibraryCubit(sl()));
  sl.registerFactory<OnboardingCubit>(() => OnboardingCubit(sl()));
  sl.registerFactory<PreferenceCubit>(() => PreferenceCubit(sl()));
  sl.registerFactory<ProfileCubit>(() => ProfileCubit(sl(), sl(), sl()));
}
