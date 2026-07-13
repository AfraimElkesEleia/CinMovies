import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:cinmovies_app/core/widgets/auth_screen_layout.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/auth_divider.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_primary_button.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_styles.dart';
import 'package:cinmovies_app/core/widgets/app_text_field.dart';
import 'package:cinmovies_app/features/login/presentation/widgets/login_with_button.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final agreedToTerms = ValueNotifier<bool>(false);

  @override
  void dispose() {
    agreedToTerms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      header: const _SignupHeader(),
      children: [
        Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTextField(
                label: 'Full Name',
                hintText: 'John Doe',
                prefixIcon: Icons.person,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              const AppTextField(
                label: 'Email',
                hintText: 'your@email.com',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const AppTextField(
                label: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const AppTextField(
                label: 'Confirm Password',
                hintText: 'Confirm your password',
                prefixIcon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 18),
              _TermsAgreement(agreedToTerms: agreedToTerms),
              const SizedBox(height: 20),
              LoginPrimaryButton(
                text: 'Create Account',
                onPressed: () {
                  context.pushNamedAndRemoveUntil(Routes.home);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AuthDivider(text: 'or continue with'),
        const SizedBox(height: 16),
        Row(
          children: [
            LoginWithButton(
              buttonText: 'Google',
              buttonIcon: 'assets/images/google_icon.png',
              onPressed: () {
                // Handle Google register logic here
              },
            ),
            const SizedBox(width: 8),
            LoginWithButton(
              buttonText: 'Facebook',
              buttonIcon: 'assets/images/facebook_icon.png',
              onPressed: () {
                // Handle Facebook register logic here
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _LoginPrompt(
          onLoginPressed: () => context.pushNamedAndRemoveUntil(Routes.login),
        ),
      ],
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Start discovering your next favorite movie',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.agreedToTerms});

  final ValueNotifier<bool> agreedToTerms;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: agreedToTerms,
      builder: (context, value, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => agreedToTerms.value = !value,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                activeColor: LoginStyles.primaryColor,
                side: const BorderSide(color: LoginStyles.borderColor),
                onChanged: (checked) {
                  agreedToTerms.value = checked ?? false;
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        const TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(color: LoginStyles.primaryColor),
                        ),
                        const TextSpan(text: ' and '),
                        const TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(color: LoginStyles.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onLoginPressed});

  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onLoginPressed,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(
                color: LoginStyles.textColor.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const TextSpan(
              text: 'Login',
              style: TextStyle(
                color: LoginStyles.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
