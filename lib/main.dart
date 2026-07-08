import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/navigation/app_router.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinMovies',
      initialRoute: Routes.splash,
      onGenerateRoute: _appRouter.generateRoute,
    );
  }
}
