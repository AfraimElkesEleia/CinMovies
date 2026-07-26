import 'package:hive_flutter/hive_flutter.dart';

class HiveCacheService {
  HiveCacheService(
    this._searchBox,
    this._movieBox,
    this._userSnapshotBox,
    this._favoriteGenresBox, {
    this._trailerHistoryBox,
  });

  static const searchBoxName = 'search_cache';
  static const movieBoxName = 'movie_cache';
  static const userSnapshotBoxName = 'user_snapshot_cache';
  static const favoriteGenresBoxName = 'favorite_genres_cache';
  static const trailerHistoryBoxName = 'trailer_history';

  final Box<dynamic> _searchBox;
  final Box<dynamic> _movieBox;
  final Box<dynamic> _userSnapshotBox;
  final Box<dynamic> _favoriteGenresBox;
  final Box<dynamic>? _trailerHistoryBox;

  static Future<HiveCacheService> initialize() async {
    await Hive.initFlutter();
    final searchBox = await Hive.openBox<dynamic>(searchBoxName);
    final movieBox = await Hive.openBox<dynamic>(movieBoxName);
    final userSnapshotBox = await Hive.openBox<dynamic>(userSnapshotBoxName);
    final favoriteGenresBox = await Hive.openBox<dynamic>(favoriteGenresBoxName);
    final trailerHistoryBox = await Hive.openBox<dynamic>(
      trailerHistoryBoxName,
    );

    return HiveCacheService(
      searchBox,
      movieBox,
      userSnapshotBox,
      favoriteGenresBox,
      trailerHistoryBox: trailerHistoryBox,
    );
  }

  List<String> getRecentSearches() {
    return _stringList(_searchBox.get('recent_searches'));
  }

  Future<void> saveRecentSearch(String query, {int limit = 6}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final searches = [
      normalized,
      ...getRecentSearches().where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(limit).toList();

    await _searchBox.put('recent_searches', searches);
  }

  Future<void> deleteRecentSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final searches = getRecentSearches()
        .where((item) => item.toLowerCase() != normalized.toLowerCase())
        .toList();

    await _searchBox.put('recent_searches', searches);
  }

  Future<void> cacheMovie(String id, Map<String, dynamic> row) async {
    await _movieBox.put(id, row);
  }

  Map<String, dynamic>? getCachedMovie(String id) {
    return _map(_movieBox.get(id));
  }

  Future<void> cacheUserSnapshot(String key, Object value) async {
    await _userSnapshotBox.put(key, value);
  }

  T? getUserSnapshot<T>(String key) {
    final value = _userSnapshotBox.get(key);
    return value is T ? value : null;
  }

  Set<String> getFavoriteGenres() {
    return _stringList(_favoriteGenresBox.get('genres')).toSet();
  }

  Future<void> cacheFavoriteGenres(Set<String> genres) async {
    await _favoriteGenresBox.put('genres', genres.toList()..sort());
  }

  List<Map<String, dynamic>> getTrailerHistory(String scopeId) {
    final prefix = _trailerKeyPrefix(scopeId);
    return _requiredTrailerHistoryBox()
        .toMap()
        .entries
        .where((entry) => entry.key is String && (entry.key as String).startsWith(prefix))
        .map((entry) => _map(entry.value))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Map<String, dynamic>? getTrailerHistoryEntry(
    String scopeId,
    String videoKey,
  ) {
    return _map(
      _requiredTrailerHistoryBox().get(_trailerKey(scopeId, videoKey)),
    );
  }

  Future<void> cacheTrailerHistoryEntry(
    String scopeId,
    String videoKey,
    Map<String, dynamic> value,
  ) async {
    await _requiredTrailerHistoryBox().put(
      _trailerKey(scopeId, videoKey),
      value,
    );
  }

  Future<void> deleteTrailerHistoryEntry(
    String scopeId,
    String videoKey,
  ) async {
    await _requiredTrailerHistoryBox().delete(
      _trailerKey(scopeId, videoKey),
    );
  }

  Stream<void> watchTrailerHistory(String scopeId) async* {
    final prefix = _trailerKeyPrefix(scopeId);
    await for (final event in _requiredTrailerHistoryBox().watch()) {
      final key = event.key;
      if (key is String && key.startsWith(prefix)) {
        yield null;
      }
    }
  }

  Box<dynamic> _requiredTrailerHistoryBox() {
    final box = _trailerHistoryBox;
    if (box == null) {
      throw StateError('Trailer history box is not configured.');
    }
    return box;
  }

  String _trailerKeyPrefix(String scopeId) => '$scopeId::';

  String _trailerKey(String scopeId, String videoKey) {
    return '${_trailerKeyPrefix(scopeId)}$videoKey';
  }

  List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().toList();
  }

  Map<String, dynamic>? _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
