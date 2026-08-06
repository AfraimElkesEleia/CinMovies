import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/auth/presentation/widgets/guest_account_prompt.dart';
import 'package:cinmovies_app/features/movie_details/presentation/widgets/movie_details_reviews_tab.dart';
import 'package:cinmovies_app/features/reviews/data/model/community_review.dart';
import 'package:cinmovies_app/features/reviews/data/model/review_reply.dart';
import 'package:cinmovies_app/features/reviews/data/review_repository.dart';
import 'package:cinmovies_app/features/reviews/presentation/cubit/review_replies_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReviewRepliesScreen extends StatelessWidget {
  const ReviewRepliesScreen({super.key, required this.review});

  final CommunityReview review;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewRepliesCubit(
        serviceLocator<ReviewRepository>(),
        review,
        isGuest: serviceLocator<AuthRepository>().isGuest,
      )..load(),
      child: const _ReviewRepliesView(),
    );
  }
}

class _ReviewRepliesView extends StatelessWidget {
  const _ReviewRepliesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Replies'),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ReviewRepliesCubit, ReviewRepliesState>(
              builder: (context, state) => RefreshIndicator(
                color: AppColors.loginPrimary,
                backgroundColor: AppColors.surface,
                onRefresh: context.read<ReviewRepliesCubit>().load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: ReviewCard(
                          review: state.review,
                          onReactionPressed: (review, reaction) =>
                              _toggleMainReviewReaction(context, reaction),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          _replyCountLabel(state.review.replyCount),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    ..._replySlivers(context, state),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
            ),
          ),
          BlocBuilder<ReviewRepliesCubit, ReviewRepliesState>(
            buildWhen: (previous, current) =>
                previous.isReplySaving != current.isReplySaving,
            builder: (context, state) => _ReplyComposer(
              isSaving: state.isReplySaving,
              onSend: (body) => _submitReply(context, body),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _replySlivers(
    BuildContext context,
    ReviewRepliesState state,
  ) {
    return switch (state.status) {
      ReviewRepliesStatus.initial || ReviewRepliesStatus.loading => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 44),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.loginPrimary),
            ),
          ),
        ),
      ],
      ReviewRepliesStatus.failure => [
        SliverToBoxAdapter(
          child: _RepliesMessage(
            icon: Icons.error_outline_rounded,
            message: 'Could not load replies.',
            actionLabel: 'Try again',
            onAction: context.read<ReviewRepliesCubit>().load,
          ),
        ),
      ],
      ReviewRepliesStatus.loaded when state.replies.isEmpty => const [
        SliverToBoxAdapter(
          child: _RepliesMessage(
            icon: Icons.chat_bubble_outline_rounded,
            message: 'No replies yet. Start the conversation.',
          ),
        ),
      ],
      ReviewRepliesStatus.loaded => [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: state.replies.length,
            itemBuilder: (context, index) {
              final reply = state.replies[index];
              return ReviewReplyCard(
                key: ValueKey(reply.id),
                reply: reply,
                onReactionPressed: (reply, reaction) =>
                    _toggleReplyReaction(context, reply, reaction),
                onDeletePressed: (reply) => _deleteReply(context, reply),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 12),
          ),
        ),
      ],
    };
  }

  String _replyCountLabel(int count) => count == 1 ? '1 Reply' : '$count Replies';

  Future<bool> _toggleMainReviewReaction(
    BuildContext context,
    ReviewReaction reaction,
  ) async {
    final cubit = context.read<ReviewRepliesCubit>();
    if (cubit.isGuest) {
      await showGuestAccountPrompt(context, feature: 'react to reviews');
      return false;
    }
    final success = await cubit.toggleReviewReaction(reaction);
    if (!success && context.mounted) {
      AppSnackBar.showError(context, 'Could not update your reaction.');
    }
    return success;
  }

  Future<bool> _toggleReplyReaction(
    BuildContext context,
    ReviewReply reply,
    ReviewReaction reaction,
  ) async {
    final cubit = context.read<ReviewRepliesCubit>();
    if (cubit.isGuest) {
      await showGuestAccountPrompt(context, feature: 'react to replies');
      return false;
    }
    final success = await cubit.toggleReplyReaction(reply, reaction);
    if (!success && context.mounted) {
      AppSnackBar.showError(context, 'Could not update your reaction.');
    }
    return success;
  }

  Future<bool> _deleteReply(BuildContext context, ReviewReply reply) async {
    final success = await context.read<ReviewRepliesCubit>().deleteReply(reply);
    if (!context.mounted) return success;
    if (success) {
      AppSnackBar.showSuccess(context, 'Reply removed.');
    } else {
      AppSnackBar.showError(context, 'Could not remove your reply.');
    }
    return success;
  }

  Future<bool> _submitReply(BuildContext context, String body) async {
    final cubit = context.read<ReviewRepliesCubit>();
    if (cubit.isGuest) {
      await showGuestAccountPrompt(context, feature: 'reply to reviews');
      return false;
    }
    final success = await cubit.submitReply(body);
    if (!context.mounted) return success;
    if (success) {
      AppSnackBar.showSuccess(context, 'Reply posted.');
    } else {
      AppSnackBar.showError(context, 'Could not post your reply.');
    }
    return success;
  }
}

class ReviewReplyCard extends StatelessWidget {
  const ReviewReplyCard({
    super.key,
    required this.reply,
    required this.onReactionPressed,
    required this.onDeletePressed,
  });

  final ReviewReply reply;
  final Future<bool> Function(ReviewReply reply, ReviewReaction reaction)
  onReactionPressed;
  final Future<bool> Function(ReviewReply reply) onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final canReact = !reply.isOwnReply;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: reply.authorAvatarUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: AppColors.surfaceBorder,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.textMuted,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reply.displayDate,
                      style: const TextStyle(
                        color: AppColors.iconMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reply.body,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.surfaceBorder),
          const SizedBox(height: 8),
          Row(
            children: [
              _ReplyReactionButton(
                icon: Icons.thumb_up_alt_outlined,
                selectedIcon: Icons.thumb_up_alt_rounded,
                label: reply.likeCount.toString(),
                selected: reply.currentUserReaction == ReviewReaction.like,
                enabled: canReact,
                onPressed: () =>
                    onReactionPressed(reply, ReviewReaction.like),
              ),
              const SizedBox(width: 18),
              _ReplyReactionButton(
                icon: Icons.thumb_down_alt_outlined,
                selectedIcon: Icons.thumb_down_alt_rounded,
                label: reply.dislikeCount.toString(),
                selected: reply.currentUserReaction == ReviewReaction.dislike,
                enabled: canReact,
                onPressed: () =>
                    onReactionPressed(reply, ReviewReaction.dislike),
              ),
              if (reply.isOwnReply) ...[
                const Spacer(),
                InkWell(
                  onTap: () => onDeletePressed(reply),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.loginPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyReactionButton extends StatelessWidget {
  const _ReplyReactionButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.loginPrimary : AppColors.iconMuted;
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyComposer extends StatefulWidget {
  const _ReplyComposer({required this.isSaving, required this.onSend});

  final bool isSaving;
  final Future<bool> Function(String body) onSend;

  @override
  State<_ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<_ReplyComposer> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() => setState(() {});

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || widget.isSaving) return;
    final success = await widget.onSend(body);
    if (success && mounted) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty && !widget.isSaving;
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write a reply...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.scaffoldBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend ? _send : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.loginPrimary,
                  disabledBackgroundColor: AppColors.surfaceBorder,
                  foregroundColor: AppColors.white,
                ),
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepliesMessage extends StatelessWidget {
  const _RepliesMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      child: Column(
        children: [
          Icon(icon, color: AppColors.iconMuted, size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
