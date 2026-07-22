import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseConfig {
  static Future<void> initialize() {
    return Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabasePublishableKey,
    );
  }
}
