import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/onboarding_screen/model/preference_model.dart';
import 'package:flutter/material.dart';

const List<PreferenceModel> movieGenres = [
  PreferenceModel(genre: 'Action', emoji: '⚡'),
  PreferenceModel(genre: 'Adventure', emoji: '🧭'),
  PreferenceModel(genre: 'Comedy', emoji: '😂'),
  PreferenceModel(genre: 'Drama', emoji: '🎭'),
  PreferenceModel(genre: 'Horror', emoji: '👻'),
  PreferenceModel(genre: 'Animation', emoji: '✨'),
  PreferenceModel(genre: 'Sci-Fi', emoji: '🚀'),
  PreferenceModel(genre: 'Romance', emoji: '❤️'),
  PreferenceModel(genre: 'Thriller', emoji: '🔪'),
  PreferenceModel(genre: 'Documentary', emoji: '🎬'),
  PreferenceModel(genre: 'Crime', emoji: '🕵️'),
  PreferenceModel(genre: 'Fantasy', emoji: '🪄'),
];

class PreferenceOnboardingScreen extends StatefulWidget {
  const PreferenceOnboardingScreen({super.key});

  @override
  State<PreferenceOnboardingScreen> createState() =>
      _PreferenceOnboardingScreenState();
}

class _PreferenceOnboardingScreenState
    extends State<PreferenceOnboardingScreen> {
  final Set<String> selectedGenres = {};

  bool get canContinue => selectedGenres.length >= 3;

  void toggleGenre(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        selectedGenres.remove(genre);
      } else {
        selectedGenres.add(genre);
      }
    });
  }

  void continueToLogin() {
    context.pushReplacementNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preferenceBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Favorite Genres',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select at least 3 genres to personalize your experience.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.preferenceSubtitle,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: movieGenres.map((genre) {
                        final isSelected = selectedGenres.contains(genre.genre);

                        return FilterChip(
                          selected: isSelected,
                          showCheckmark: false,
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.preferenceSelectedChip,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.preferenceSelectedBorder
                                : AppColors.preferenceChipBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          label: Text(
                            '${genre.emoji}  ${genre.genre}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.preferenceChipText,
                            ),
                          ),
                          onSelected: (_) => toggleGenre(genre.genre),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Select at least 3 genres (${selectedGenres.length} selected)',
                  style: TextStyle(
                    color: canContinue
                        ? AppColors.preferenceChipText
                        : AppColors.preferenceMutedText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canContinue ? continueToLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.preferenceButton,
                    disabledBackgroundColor:
                        AppColors.preferenceDisabledButton,
                    foregroundColor: AppColors.white,
                    disabledForegroundColor: AppColors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
