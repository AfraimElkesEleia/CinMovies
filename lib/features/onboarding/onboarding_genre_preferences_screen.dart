import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/features/onboarding/presentation/cubit/onboarding_genre_preferences_cubit.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:cinmovies_app/features/preferences/domain/movie_genre_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingGenrePreferencesScreen extends StatelessWidget {
  const OnboardingGenrePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingGenrePreferencesCubit(
        serviceLocator<GenrePreferencesRepository>(),
      ),
      child:
          BlocListener<
            OnboardingGenrePreferencesCubit,
            OnboardingGenrePreferencesState
          >(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == OnboardingGenrePreferencesStatus.saved) {
            context.pushNamedAndRemoveUntil(AppRoutes.home);
          }

          if (state.status == OnboardingGenrePreferencesStatus.failure) {
            context.pushReplacementNamed(AppRoutes.login);
          }
        },
        child: const _GenrePreferencesView(),
      ),
    );
  }
}

class _GenrePreferencesView extends StatelessWidget {
  const _GenrePreferencesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      OnboardingGenrePreferencesCubit,
      OnboardingGenrePreferencesState
    >(
      builder: (context, state) {
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
                          children: movieGenreOptions.map((genre) {
                            final isSelected = state.selectedGenres.contains(
                              genre.genre,
                            );

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
                              onSelected: (_) {
                                context
                                    .read<OnboardingGenrePreferencesCubit>()
                                    .toggleGenre(genre.genre);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Select at least 3 genres (${state.selectedGenres.length} selected)',
                      style: TextStyle(
                        color: state.canContinue
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
                      onPressed: state.canContinue && !state.isSaving
                          ? context
                                .read<OnboardingGenrePreferencesCubit>()
                                .save
                          : null,
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
                      child: Text(
                        state.isSaving ? 'Saving...' : 'Continue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
