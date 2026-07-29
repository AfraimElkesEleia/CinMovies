import 'package:cinmovies_app/core/di/injection_container.dart';
import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/widgets/app_snack_bar.dart';
import 'package:cinmovies_app/core/widgets/auth_screen_layout.dart';
import 'package:cinmovies_app/features/auth/data/auth_repository.dart';
import 'package:cinmovies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_header.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_primary_button.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_options_row.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/signup_prompt.dart';
import 'package:cinmovies_app/features/preferences/data/genre_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<GenrePreferencesRepository>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthSubmissionStatus.success) {
          context.pushNamedAndRemoveUntil(AppRoutes.home);
        }

        if (state.status == AuthSubmissionStatus.failure &&
            state.errorMessage != null) {
          AppSnackBar.showError(context, state.errorMessage!);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return AuthScreenLayout(
            header: const LoginHeader(),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Email',
                      hintText: 'your@email.com',
                      prefixIcon: Icons.email,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _requiredEmail,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icons.lock,
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: _requiredPassword,
                      onSubmitted: (_) => _login(context),
                    ),
                    LoginOptionsRow(
                      rememberMe: state.rememberMe,
                      onRememberMeChanged: context
                          .read<AuthCubit>()
                          .setRememberMe,
                      onForgotPasswordPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    LoginPrimaryButton(
                      text:
                          state.isLoadingOperation(
                            AuthSubmissionOperation.login,
                          )
                          ? 'Logging in...'
                          : 'Login',
                      onPressed: state.isLoading ? null : () => _login(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : context.read<AuthCubit>().continueAsGuest,
                  icon: const Icon(Icons.movie_filter_outlined),
                  label: Text(
                    state.isLoadingOperation(AuthSubmissionOperation.guest)
                        ? 'Continuing...'
                        : 'Continue as Guest',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SignupPrompt(
                onSignUpPressed: () => context.pushNamed(AppRoutes.register),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _requiredEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? _requiredPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    return null;
  }

  void _login(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }
}
