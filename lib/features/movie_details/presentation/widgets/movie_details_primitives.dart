import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';
import 'package:flutter/material.dart';

class DetailsGlassIconButton extends StatelessWidget {
  const DetailsGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.white,
    this.size = 22,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.scaffoldBackground.withValues(alpha: 0.72),
        foregroundColor: color,
        fixedSize: const Size(40, 40),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: size),
    );
  }
}

class DetailsAvailabilityBadge extends StatelessWidget {
  const DetailsAvailabilityBadge({super.key, required this.availability});

  final MovieAvailability availability;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (availability) {
      MovieAvailability.streaming => ('STREAMING NOW', const Color(0xFF059669)),
      MovieAvailability.comingSoon => (
        'COMING SOON',
        AppColors.comingSoonPurple,
      ),
      MovieAvailability.rental => ('RENTAL ONLY', AppColors.ratingAmber),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailsGenreChip extends StatelessWidget {
  const DetailsGenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceBorder.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DetailsMetaText extends StatelessWidget {
  const DetailsMetaText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class DetailsMetaDot extends StatelessWidget {
  const DetailsMetaDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.surfaceBorder,
        shape: BoxShape.circle,
      ),
    );
  }
}

class DetailsAgeRating extends StatelessWidget {
  const DetailsAgeRating({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DetailsPlayerButton extends StatelessWidget {
  const DetailsPlayerButton({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: AppColors.textMuted, size: 25);
  }
}
