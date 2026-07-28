import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/library/data/library_repository.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_details_tab.dart';
import 'package:cinmovies_app/features/movie_details/data/movie_details_repository.dart';
import 'package:cinmovies_app/features/movie_details/presentation/model/movie_share_content.dart';
import 'package:cinmovies_app/features/movie_details/presentation/cubit/movie_details_cubit.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_backdrop.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_cast_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_info.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_overview_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_reviews_tab.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/similar_movies_section.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:cinmovies_app/features/trailers/presentation/model/trailer_viewer_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

class MovieDetailsScreen extends StatelessWidget {
  const MovieDetailsScreen({
    super.key,
    required this.movie,
    required this.heroTag,
  });

  final Movie movie;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MovieDetailsCubit(
        serviceLocator<MovieDetailsRepository>(),
        serviceLocator<LibraryRepository>(),
        serviceLocator<ReviewRepository>(),
        movie,
        isGuest: serviceLocator<AuthRepository>().isGuest,
      )..load(),
      child: _MovieDetailsView(heroTag: heroTag),
    );
  }
}

// ─── Main View ───────────────────────────────────────────────────────────────

class _MovieDetailsView extends StatelessWidget {
  const _MovieDetailsView({required this.heroTag});

  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: MovieDetailsTab.values.length,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: NestedScrollView(
          headerSliverBuilder: _buildHeaderSlivers,
          body: TabBarView(
            children: [_OverviewTabBody(), _CastTabBody(), _ReviewsTabBody()],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeaderSlivers(
    BuildContext context,
    bool innerBoxIsScrolled,
  ) {
    return [
      // Backdrop — only rebuilds when image/favorite state changes
      SliverToBoxAdapter(
        child: BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
          buildWhen: (prev, curr) =>
              prev.movie != curr.movie ||
              prev.isFavorite != curr.isFavorite ||
              prev.isFavoriteLoading != curr.isFavoriteLoading ||
              prev.isFavoriteSaving != curr.isFavoriteSaving,
          builder: (context, state) => MovieDetailsBackdrop(
            movie: state.movie,
            heroTag: heroTag,
            isFavorite: state.isFavorite,
            isFavoriteLoading:
                state.isFavoriteLoading || state.isFavoriteSaving,
            onBackPressed: Navigator.of(context).pop,
            onFavoritePressed: () => _toggleFavorite(context),
            onSharePressed: (shareOrigin) =>
                _shareMovie(context, state.movie, shareOrigin),
          ),
        ),
      ),
      // Info — only rebuilds when movie info, watchlist, or trailer state changes
      SliverToBoxAdapter(
        child: BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
          buildWhen: (prev, curr) =>
              prev.movie != curr.movie ||
              prev.inWatchlist != curr.inWatchlist ||
              prev.isWatchlistLoading != curr.isWatchlistLoading ||
              prev.isWatchlistSaving != curr.isWatchlistSaving ||
              prev.isDetailsLoading != curr.isDetailsLoading ||
              prev.videoKey != curr.videoKey,
          builder: (context, state) => MovieDetailsInfo(
            movie: state.movie,
            inWatchlist: state.inWatchlist,
            isWatchlistLoading:
                state.isWatchlistLoading || state.isWatchlistSaving,
            isTrailerLoading: state.isDetailsLoading,
            isTrailerAvailable: state.videoKey != null,
            onTrailerPressed: () => _openTrailer(context, state),
            onWatchlistPressed: () => _toggleWatchlist(context),
          ),
        ),
      ),
      // Pinned tab bar — absorbs overlap so each tab body knows how much
      // space to reserve at the top via SliverOverlapInjector.
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: SliverPersistentHeader(
          pinned: true,
          delegate: _StickyTabBarDelegate(),
        ),
      ),
    ];
  }

  // ── Action handlers ────────────────────────────────────────────────────────

  Future<void> _toggleFavorite(BuildContext context) async {
    final success = await context.read<MovieDetailsCubit>().toggleFavorite();
    if (!success && context.mounted) {
      AppSnackBar.showInfo(context, 'Sign in to update your favorite movies.');
    }
  }

  Future<void> _toggleWatchlist(BuildContext context) async {
    final success = await context.read<MovieDetailsCubit>().toggleWatchlist();
    if (!success && context.mounted) {
      AppSnackBar.showInfo(context, 'Sign in to update your watchlist.');
    }
  }

  void _openTrailer(BuildContext context, MovieDetailsState state) {
    final videoKey = state.videoKey;
    if (videoKey == null || videoKey.trim().isEmpty) return;
    final movie = state.movie;
    context.pushNamed(
      AppRoutes.trailerViewer,
      arguments: TrailerViewerArgs(
        videoKey: videoKey,
        movieId: movie.id,
        title: movie.title,
        imageAsset: movie.imageAsset,
      ),
    );
  }

  Future<void> _shareMovie(
    BuildContext context,
    Movie movie,
    Rect? shareOrigin,
  ) async {
    final content = MovieShareContent.fromMovie(movie);

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: content.title,
          subject: content.subject,
          text: content.text,
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Could not open sharing options.');
      }
    }
  }
}

// ─── Tab Bodies ───────────────────────────────────────────────────────────────
// Each tab body uses Builder + CustomScrollView so that SliverOverlapInjector
// can communicate the pinned tab bar height to the scroll view, preventing the
// tab content from being hidden under the tab bar on first render.

class _OverviewTabBody extends StatelessWidget {
  const _OverviewTabBody();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
              buildWhen: (prev, curr) =>
                  prev.movie != curr.movie ||
                  prev.similarMovies != curr.similarMovies,
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MovieDetailsOverviewTab(movie: state.movie),
                  SimilarMoviesSection(
                    movies: state.similarMovies,
                    onMoviePressed: (movie, heroTag) =>
                        _openSimilarMovie(context, movie, heroTag),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSimilarMovie(BuildContext context, Movie movie, String heroTag) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MovieDetailsScreen(movie: movie, heroTag: heroTag),
      ),
    );
  }
}

class _CastTabBody extends StatelessWidget {
  const _CastTabBody();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
              buildWhen: (prev, curr) => prev.movie != curr.movie,
              builder: (context, state) =>
                  MovieDetailsCastTab(cast: state.movie.cast),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsTabBody extends StatelessWidget {
  const _ReviewsTabBody();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
              buildWhen: (prev, curr) =>
                  prev.reviews != curr.reviews ||
                  prev.isReviewsLoading != curr.isReviewsLoading ||
                  prev.isReviewSaving != curr.isReviewSaving,
              builder: (context, state) => MovieDetailsReviewsTab(
                reviews: state.reviews,
                isLoading: state.isReviewsLoading,
                isReviewSaving: state.isReviewSaving,
                onWriteReviewPressed: () => _writeReview(context),
                onReactionPressed: (review, reaction) => context
                    .read<MovieDetailsCubit>()
                    .toggleReviewReaction(review, reaction),
                onDeletePressed: (review) => _deleteReview(context, review),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _writeReview(BuildContext context) async {
    final request = await showModalBottomSheet<ReviewComposerRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => const ReviewComposerSheet(),
    );
    if (request == null || !context.mounted) return;

    final success = await context.read<MovieDetailsCubit>().submitReview(
      rating: request.rating,
      title: request.title,
      body: request.body,
      spoiler: request.spoiler,
    );
    if (!context.mounted) return;

    if (success) {
      AppSnackBar.showSuccess(context, 'Review saved.');
    } else {
      AppSnackBar.showError(context, 'Could not save your review.');
    }
  }

  Future<bool> _deleteReview(
    BuildContext context,
    CommunityReview review,
  ) async {
    final success = await context.read<MovieDetailsCubit>().deleteReview(
      review,
    );
    if (!context.mounted) return success;

    if (success) {
      AppSnackBar.showSuccess(context, 'Review removed.');
    } else {
      AppSnackBar.showError(context, 'Could not remove your review.');
    }
    return success;
  }
}

// ─── Sticky Tab Bar Delegate ─────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  static const double _kTabBarHeight = 44.0;
  static const double _kVerticalPadding = 24.0; // 16 top + 8 bottom
  static const double _kTotalHeight = _kTabBarHeight + _kVerticalPadding;

  @override
  double get minExtent => _kTotalHeight;

  @override
  double get maxExtent => _kTotalHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColors.scaffoldBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: TabBar(
          tabs: [
            for (final tab in MovieDetailsTab.values) Tab(text: tab.label),
          ],
          tabAlignment: TabAlignment.fill,
          indicator: BoxDecoration(
            color: AppColors.surfaceBorder,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.iconMuted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Tab bar content is static — DefaultTabController handles animation.
  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => false;
}
