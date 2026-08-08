import 'dart:async';

import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/features/trailers/domain/entities/trailer_history_entry.dart';
import 'package:cinmovies_app/features/trailers/presentation/model/trailer_viewer_args.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum TrailerPlaybackStatus { loading, ready, failure }

class TrailerPlaybackState extends Equatable {
  const TrailerPlaybackState({
    this.status = TrailerPlaybackStatus.loading,
    this.initialSeconds = 0,
    this.errorMessage,
  });

  final TrailerPlaybackStatus status;
  final int initialSeconds;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, initialSeconds, errorMessage];
}

class TrailerPlaybackCubit extends Cubit<TrailerPlaybackState> {
  TrailerPlaybackCubit(this._repository, this.args)
    : super(const TrailerPlaybackState());

  static const saveInterval = Duration(seconds: 5);
  static const _maxFlushDepth = 2;

  final TrailerHistoryRepositoryContract _repository;
  final TrailerViewerArgs args;

  Timer? _saveTimer;
  int _latestSeconds = 0;
  int _totalSeconds = 0;
  int _lastSavedSeconds = -1;
  bool _hasUnsavedProgress = false;
  Future<bool>? _activeSave;

  Future<void> initialize() async {
    emit(const TrailerPlaybackState());
    final result = await _repository.findByVideoKey(args.videoKey);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        TrailerPlaybackState(
          status: TrailerPlaybackStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (entry) {
        final initialSeconds = entry == null || entry.isComplete
            ? 0
            : entry.watchedSeconds;
        _latestSeconds = initialSeconds;
        _totalSeconds = entry?.totalSeconds ?? 0;
        _lastSavedSeconds = entry?.watchedSeconds ?? -1;
        emit(
          TrailerPlaybackState(
            status: TrailerPlaybackStatus.ready,
            initialSeconds: initialSeconds,
          ),
        );
      },
    );
  }

  void updateProgress(Duration position, Duration total) {
    final totalSeconds = total.inSeconds;
    if (totalSeconds <= 0) return;

    final watchedSeconds = position.inSeconds.clamp(0, totalSeconds);
    _totalSeconds = totalSeconds;
    _latestSeconds = watchedSeconds;
    _hasUnsavedProgress = watchedSeconds != _lastSavedSeconds;
    _saveTimer ??= Timer.periodic(saveInterval, (_) {
      unawaited(flushProgress());
    });
  }

  Future<void> markCompleted(Duration total) async {
    if (total.inSeconds <= 0) return;
    _totalSeconds = total.inSeconds;
    _latestSeconds = _totalSeconds;
    _hasUnsavedProgress = true;
    await flushProgress();
  }

  Future<void> flushProgress({int depth = 0}) async {
    if (depth > _maxFlushDepth) return;
    final activeSave = _activeSave;
    if (activeSave != null) {
      final succeeded = await activeSave;
      if (succeeded && _hasUnsavedProgress) {
        await flushProgress(depth: depth + 1);
      }
      return;
    }
    if (!_hasUnsavedProgress || _totalSeconds <= 0) return;

    final watchedSeconds = _latestSeconds.clamp(0, _totalSeconds);
    final totalSeconds = _totalSeconds;
    _hasUnsavedProgress = false;
    final save = _saveSnapshot(watchedSeconds, totalSeconds);
    _activeSave = save;
    final succeeded = await save;
    if (identical(_activeSave, save)) _activeSave = null;
    if (succeeded && _hasUnsavedProgress) {
      await flushProgress(depth: depth + 1);
    }
  }

  Future<bool> _saveSnapshot(int watchedSeconds, int totalSeconds) async {
    final result = await _repository.saveProgress(
      TrailerHistoryEntry(
        videoKey: args.videoKey,
        movieId: args.movieId,
        title: args.title,
        imageAsset: args.imageAsset,
        watchedSeconds: watchedSeconds,
        totalSeconds: totalSeconds,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    return result.fold(
      (_) {
        _hasUnsavedProgress = true;
        return false;
      },
      (_) {
        _lastSavedSeconds = watchedSeconds;
        return true;
      },
    );
  }

  void reportPlayerError() {
    if (isClosed) return;
    emit(
      const TrailerPlaybackState(
        status: TrailerPlaybackStatus.failure,
        errorMessage: 'This trailer could not be played.',
      ),
    );
  }

  @override
  Future<void> close() async {
    _saveTimer?.cancel();
    await flushProgress();
    return super.close();
  }
}
