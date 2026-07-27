import 'dart:async';

import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/trailers/data/trailer_history_repository.dart';
import 'package:cinmovies_app/features/trailers/presentation/cubit/trailer_playback_cubit.dart';
import 'package:cinmovies_app/features/trailers/presentation/model/trailer_viewer_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrailerViewerScreen extends StatelessWidget {
  const TrailerViewerScreen({super.key, required this.args});

  final TrailerViewerArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TrailerPlaybackCubit(serviceLocator<TrailerHistoryRepository>(), args)
            ..initialize(),
      child: _TrailerViewerView(args: args),
    );
  }
}

class _TrailerViewerView extends StatelessWidget {
  const _TrailerViewerView({required this.args});

  final TrailerViewerArgs args;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          unawaited(context.read<TrailerPlaybackCubit>().flushProgress());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          title: Text(
            'Trailer: ${args.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: BlocBuilder<TrailerPlaybackCubit, TrailerPlaybackState>(
          builder: (context, state) {
            return switch (state.status) {
              TrailerPlaybackStatus.loading => const Center(
                child: CircularProgressIndicator(color: AppColors.loginPrimary),
              ),
              TrailerPlaybackStatus.failure => _TrailerError(
                message:
                    state.errorMessage ?? 'This trailer could not be played.',
                onRetry: context.read<TrailerPlaybackCubit>().initialize,
              ),
              TrailerPlaybackStatus.ready => _YoutubeTrailerPlayer(
                key: ValueKey('${args.videoKey}-${state.initialSeconds}'),
                args: args,
                initialSeconds: state.initialSeconds,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _YoutubeTrailerPlayer extends StatefulWidget {
  const _YoutubeTrailerPlayer({
    super.key,
    required this.args,
    required this.initialSeconds,
  });

  final TrailerViewerArgs args;
  final int initialSeconds;

  @override
  State<_YoutubeTrailerPlayer> createState() => _YoutubeTrailerPlayerState();
}

class _YoutubeTrailerPlayerState extends State<_YoutubeTrailerPlayer>
    with WidgetsBindingObserver {
  late final YoutubePlayerController _controller;
  late final TrailerPlaybackCubit _cubit;
  StreamSubscription<YoutubeVideoState>? _videoStateSubscription;
  StreamSubscription<YoutubePlayerValue>? _playerValueSubscription;
  bool _reportedError = false;
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<TrailerPlaybackCubit>();
    WidgetsBinding.instance.addObserver(this);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.args.videoKey,
      autoPlay: true,
      startSeconds: widget.initialSeconds.toDouble(),
      params: const YoutubePlayerParams(
        playsInline: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        privacyEnhancedMode: true,
      ),
    );
    _videoStateSubscription = _controller.videoStateStream.listen((videoState) {
      _cubit.updateProgress(videoState.position, _controller.metadata.duration);
    });
    _playerValueSubscription = _controller.stream.listen((value) {
      if (value.hasError && !_reportedError) {
        _reportedError = true;
        _cubit.reportPlayerError();
        return;
      }
      if (value.playerState == PlayerState.paused) {
        unawaited(_cubit.flushProgress());
      }
      if (value.playerState == PlayerState.ended && !_reportedCompletion) {
        _reportedCompletion = true;
        unawaited(_cubit.markCompleted(value.metaData.duration));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_cubit.flushProgress());
      unawaited(_controller.pauseVideo());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1200,
                maxHeight: constraints.maxHeight,
              ),
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
                backgroundColor: AppColors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cubit.flushProgress());
    unawaited(_videoStateSubscription?.cancel());
    unawaited(_playerValueSubscription?.cancel());
    unawaited(_controller.close());
    super.dispose();
  }
}

class _TrailerError extends StatelessWidget {
  const _TrailerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.loginPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
