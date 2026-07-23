import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/features/onboarding_screen/data/preference_repository.dart';
import 'package:cinmovies_app/features/onboarding_screen/preference_onboarding_screen.dart';
import 'package:cinmovies_app/features/profile/presentation/cubit/favorite_genres_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteGenresScreen extends StatelessWidget {
  const FavoriteGenresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavoriteGenresCubit(sl<PreferenceRepository>())..load(),
      child: const _FavoriteGenresView(),
    );
  }
}

class _FavoriteGenresView extends StatelessWidget {
  const _FavoriteGenresView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FavoriteGenresCubit, FavoriteGenresState>(
      listener: (context, state) {
        if (state.status == FavoriteGenresStatus.failure &&
            state.errorMessage != null) {
          AppSnackBar.showError(context, state.errorMessage!);
        }

        if (state.status == FavoriteGenresStatus.saved) {
          AppSnackBar.showSuccess(context, 'Favorite genres updated.');
          Navigator.pop(context, true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.preferenceBackground,
          appBar: AppBar(
            backgroundColor: AppColors.preferenceBackground,
            foregroundColor: AppColors.white,
            elevation: 0,
            title: const Text('Favorite Genres'),
          ),
          body: SafeArea(
            child: state.status == FavoriteGenresStatus.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.loginPrimary,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Your Genres',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Add or remove genres to tune your recommendations.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.preferenceSubtitle,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: movieGenres.map((genre) {
                                  final isSelected = state.selectedGenres
                                      .contains(genre.genre);

                                  return FilterChip(
                                    selected: isSelected,
                                    showCheckmark: false,
                                    backgroundColor: AppColors.surface,
                                    selectedColor:
                                        AppColors.preferenceSelectedChip,
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
                                    onSelected: (_) => context
                                        .read<FavoriteGenresCubit>()
                                        .toggleGenre(genre.genre),
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
                              color: state.canSave
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
                            onPressed: state.canSave && !state.isBusy
                                ? context.read<FavoriteGenresCubit>().save
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
                              state.status == FavoriteGenresStatus.saving
                                  ? 'Saving...'
                                  : 'Save Genres',
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
