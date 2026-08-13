import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/result.dart';
import 'package:cinmovies_app/core/local/hive_cache_service.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TrailerHistoryRepository {
  Future<Result<List<TrailerHistoryEntry>>> history();

  Future<Result<TrailerHistoryEntry?>> findByVideoKey(String videoKey);

  Future<Result<void>> saveProgress(TrailerHistoryEntry entry);

  Future<Result<void>> remove(String videoKey);

  Stream<List<TrailerHistoryEntry>> watchHistory();
}

final class HiveTrailerHistoryRepository implements TrailerHistoryRepository {
  HiveTrailerHistoryRepository(
    this._cache,
    this._supabase,
    this._errorMapper, {
    this._scopeIdResolver,
  });

  final HiveCacheService _cache;
  final SupabaseClient _supabase;
  final ErrorMapper _errorMapper;
  final String Function()? _scopeIdResolver;

  String get _scopeId {
    return _scopeIdResolver?.call() ??
        _supabase.auth.currentUser?.id ??
        'guest';
  }

  @override
  Future<Result<List<TrailerHistoryEntry>>> history() async {
    try {
      return Success(await _historyForScope(_scopeId));
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
  }

  @override
  Future<Result<TrailerHistoryEntry?>> findByVideoKey(String videoKey) async {
    try {
      final key = videoKey.trim();
      if (key.isEmpty) return const Success(null);
      final map = _cache.getTrailerHistoryEntry(_scopeId, key);
      if (map == null) return const Success(null);
      final entry = _tryParse(map);
      return Success(
        entry != null && entry.videoKey.isNotEmpty && entry.totalSeconds > 0
            ? entry
            : null,
      );
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
  }

  @override
  Future<Result<void>> saveProgress(TrailerHistoryEntry entry) async {
    try {
      final normalized = entry.normalized();
      if (normalized.videoKey.isEmpty || normalized.totalSeconds <= 0) {
        return const Success(null);
      }
      await _cache.cacheTrailerHistoryEntry(
        _scopeId,
        normalized.videoKey,
        normalized.toMap(),
      );
      return const Success(null);
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
  }

  @override
  Future<Result<void>> remove(String videoKey) async {
    try {
      final key = videoKey.trim();
      if (key.isEmpty) return const Success(null);
      await _cache.deleteTrailerHistoryEntry(_scopeId, key);
      return const Success(null);
    } catch (error) {
      return _errorMapper.toFailure(error);
    }
  }

  @override
  Stream<List<TrailerHistoryEntry>> watchHistory() async* {
    final scopeId = _scopeId;
    yield await _historyForScope(scopeId);
    await for (final _ in _cache.watchTrailerHistory(scopeId)) {
      yield await _historyForScope(scopeId);
    }
  }

  Future<List<TrailerHistoryEntry>> _historyForScope(String scopeId) async {
    try {
      final entries =
          _cache
              .getTrailerHistory(scopeId)
              .map(_tryParse)
              .whereType<TrailerHistoryEntry>()
              .where(
                (entry) => entry.videoKey.isNotEmpty && entry.totalSeconds > 0,
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return entries;
    } catch (_) {
      return const [];
    }
  }

  TrailerHistoryEntry? _tryParse(Map<String, dynamic> map) {
    try {
      return TrailerHistoryEntry.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}
