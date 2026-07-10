import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
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
      backgroundColor: const Color(0xFF070B16),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select at least 3 genres to personalize your experience.',
                style: TextStyle(fontSize: 16, color: Color(0xFF9BBBE8)),
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
                          backgroundColor: const Color(0xFF0F1320),
                          selectedColor: const Color(0xFF542078),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF9C4DCC)
                                : const Color(0xFF293147),
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
                                  ? Colors.white
                                  : const Color(0xFFAFCBF2),
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
                        ? const Color(0xFFAFCBF2)
                        : const Color(0xFF7793BC),
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
                    backgroundColor: const Color(0xFF7C1951),
                    disabledBackgroundColor: const Color(0xFF391B45),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey,
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
