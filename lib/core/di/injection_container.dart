import 'package:cinmovies_app/core/error/default_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/features/ai/data/gemini_service.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_ai_data_source.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_local_data_source.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_remote_data_source.dart';
import 'package:cinmovies_app/features/ai/data/movie_chat_repository_impl.dart';
import 'package:cinmovies_app/features/ai/data/tmdb_catalog_service.dart';
import 'package:cinmovies_app/features/ai/domain/repositories/movie_chat_repository.dart';
import 'package:cinmovies_app/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:cinmovies_app/features/browse/data/browse_repository.dart';
import 'package:cinmovies_app/features/browse/presentation/cubit/browse_cubit.dart';
import 'package:cinmovies_app/features/home/data/home_repository.dart';
import 'package:cinmovies_app/features/home/presentation/model/movie_section_args.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:cinmovies_app/features/home/presentation/cubit/movie_section_cubit.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:cinmovies_app/features/main/presentation/cubit/main_navigation_cubit.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:cinmovies_app/features/movies/data/movie_repository.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:cinmovies_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:cinmovies_app/features/onboarding/presentation/cubit/onboarding_genre_preferences_cubit.dart';
import 'package:cinmovies_app/features/profile/data/profile_repository.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:cinmovies_app/features/search/data/search_repository.dart';
import 'package:cinmovies_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/core/network/dio_client_factory.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies({
  required HiveCacheService hiveCacheService,
  required SharedPreferences sharedPreferences,
}) async {
  serviceLocator.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );
  serviceLocator.registerLazySingleton<Dio>(DioClientFactory.createTmdb);
  serviceLocator.registerLazySingleton<ErrorMapper>(DefaultErrorMapper.new);
  serviceLocator.registerLazySingleton<SupabaseDatabaseService>(
    () => SupabaseDatabaseService(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<SupabaseStorageService>(
    () => SupabaseStorageService(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<HiveCacheService>(
    () => hiveCacheService,
  );
  serviceLocator.registerLazySingleton<LocalPreferencesService>(
    () => LocalPreferencesService(sharedPreferences),
  );
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<ProfileRepository>(
    () => SupabaseProfileRepository(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<HomeRepository>(
    () => TmdbHomeRepository(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<BrowseRepository>(
    () => TmdbBrowseRepository(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<SearchRepository>(
    () => TmdbSearchRepository(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<MovieDetailsRepository>(
    () => TmdbMovieDetailsRepository(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<MovieRepository>(
    () => MovieRepository(serviceLocator(), serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<LibraryRepository>(
    () => SupabaseLibraryRepository(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<ReviewRepository>(
    () => SupabaseReviewRepository(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<GenrePreferencesRepository>(
    () => CachedGenrePreferencesRepository(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<GeminiService>(
    () => GeminiService(DioClientFactory.createGemini()),
  );
  serviceLocator.registerLazySingleton<TmdbCatalogService>(
    () => TmdbCatalogService(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<MovieChatAiDataSource>(
    () => MovieChatAiDataSource(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<MovieChatRemoteDataSource>(
    () => MovieChatRemoteDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<MovieChatLocalDataSource>(
    () => MovieChatLocalDataSource(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<MovieChatRepository>(
    () => MovieChatRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<TrailerHistoryRepository>(
    () => HiveTrailerHistoryRepository(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory<AuthCubit>(
    () => AuthCubit(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerFactory<MainNavigationCubit>(MainNavigationCubit.new);
  serviceLocator.registerFactory<HomeCubit>(
    () => HomeCubit(serviceLocator(), serviceLocator()),
  );
  serviceLocator
      .registerFactoryParam<MovieSectionCubit, MovieSectionArgs, void>(
        (args, _) =>
            MovieSectionCubit(serviceLocator(), args, serviceLocator()),
      );
  serviceLocator.registerFactory<BrowseCubit>(
    () => BrowseCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<SearchCubit>(
    () => SearchCubit(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerFactory<LibraryCubit>(
    () => LibraryCubit(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<OnboardingGenrePreferencesCubit>(
    () => OnboardingGenrePreferencesCubit(serviceLocator()),
  );
  serviceLocator.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<AiChatCubit>(
    () => AiChatCubit(serviceLocator()),
  );
}
