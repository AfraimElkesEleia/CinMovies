import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/core/local/local_preferences_service.dart';
import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';

class GenrePreferencesRepository {
  const GenrePreferencesRepository(
    this._database,
    this._cache,
    this._preferences,
  );

  final SupabaseDatabaseService _database;
  final HiveCacheService _cache;
  final LocalPreferencesService _preferences;

  String? get userScopeId {
    final user = _database.currentUser;
    if (user == null || user.isAnonymous) return null;
    return user.id;
  }

  String get _userId {
    final id = userScopeId;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Set<String> cachedFavoriteGenres() {
    final scopeId = userScopeId;
    if (scopeId == null) return const {};
    return _cache.getFavoriteGenres(scopeId: scopeId);
  }

  Stream<Set<String>> watchFavoriteGenres() {
    final scopeId = userScopeId;
    if (scopeId == null) return const Stream.empty();
    return _cache.watchFavoriteGenres(scopeId: scopeId);
  }

  Future<Set<String>> loadFavoriteGenres() async {
    final userId = _userId;
    final rows = await _database
        .from('user_genre_preferences')
        .select('genres(name)')
        .eq('user_id', userId);

    final genres = rows
        .map<String?>((row) {
          final genre = row['genres'];
          if (genre is! Map<String, dynamic>) return null;
          return genre['name'] as String?;
        })
        .whereType<String>()
        .toSet();

    await _cache.cacheFavoriteGenres(genres, scopeId: userId);
    return genres;
  }

  Future<void> saveFavoriteGenres(Set<String> genreNames) async {
    await _cache.cacheFavoriteGenres(genreNames, scopeId: _userId);
    await _preferences.setHasPassedOnboarding(true);
    await syncCachedFavoriteGenres();
  }

  Future<void> syncCachedFavoriteGenres() async {
    final userId = _userId;
    final genreNames = _cache.getFavoriteGenres(scopeId: userId);
    if (genreNames.isEmpty) return;

    final genres = await _database
        .from('genres')
        .select('id, name')
        .inFilter('name', genreNames.toList());

    await _database
        .from('user_genre_preferences')
        .delete()
        .eq('user_id', userId);

    final rows = genres
        .map<Map<String, dynamic>>(
          (genre) => {'user_id': userId, 'genre_id': genre['id']},
        )
        .toList();

    if (rows.isNotEmpty) {
      await _database.from('user_genre_preferences').insert(rows);
    }

    await _database
        .from('profiles')
        .update({'onboarding_completed': true})
        .eq('id', userId);
  }
}
