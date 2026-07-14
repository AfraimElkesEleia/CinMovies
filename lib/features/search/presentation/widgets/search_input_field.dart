import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SearchInputField extends StatelessWidget {
  const SearchInputField({
    super.key,
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClearPressed,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          hintText: 'Search movies, actors, directors...',
          hintStyle: const TextStyle(color: AppColors.iconMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.iconMuted,
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  onPressed: onClearPressed,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.iconMuted,
                  ),
                )
              : const Icon(Icons.mic_none_rounded, color: AppColors.iconMuted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.loginPrimary),
          ),
        ),
      ),
    );
  }
}
