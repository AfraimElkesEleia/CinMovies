import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/movies/domain/entities/movie.dart';
import 'package:flutter/material.dart';

class MovieDetailsCastTab extends StatelessWidget {
  const MovieDetailsCastTab({super.key, required this.cast});

  final List<MovieCastMember> cast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('cast'),
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return _CastMemberAvatar(actor: cast[index]);
        },
      ),
    );
  }
}

class _CastMemberAvatar extends StatelessWidget {
  const _CastMemberAvatar({required this.actor});

  final MovieCastMember actor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                actor.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: AppColors.surface,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            actor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          Text(
            actor.character,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.iconMuted,
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
