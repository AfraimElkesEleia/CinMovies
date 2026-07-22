import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/core/navigation/app_router.dart';
import 'package:cinmovies_app/core/supabase/supabase_config.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/app/presentation/cubit/app_bootstrap_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  final hiveCacheService = await HiveCacheService.initialize();
  final sharedPreferences = await SharedPreferences.getInstance();
  await SupabaseConfig.initialize();
  await initDependencies(
    hiveCacheService: hiveCacheService,
    sharedPreferences: sharedPreferences,
  );
  final bootstrapCubit = AppBootstrapCubit(sl(), sl());
  final initialRoute = await bootstrapCubit.resolveInitialRoute();
  await bootstrapCubit.close();
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});

  static const _appRouter = AppRouter();
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppBootstrapCubit(sl(), sl())),
      ],
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'OpenSans',
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
        title: 'CinMovies',
        initialRoute: initialRoute,
        onGenerateRoute: _appRouter.generateRoute,
      ),
    );
  }
}
