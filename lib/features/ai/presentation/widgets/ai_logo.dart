import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AiLogo extends StatelessWidget {
  const AiLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.loginPrimary, AppColors.comingSoonPurple],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: AppColors.white,
        size: size * 0.44,
      ),
    );
  }
}

class OnlineDot extends StatelessWidget {
  const OnlineDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF10B981),
        shape: BoxShape.circle,
      ),
    );
  }
}
