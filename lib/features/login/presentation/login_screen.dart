import 'package:cinmovies_app/core/extensions/context_extension.dart';
import 'package:cinmovies_app/core/navigation/routes.dart';
import 'package:cinmovies_app/core/widgets/auth_screen_layout.dart';
import 'package:flutter/material.dart';

import 'widgets/auth_divider.dart';
import 'widgets/login_header.dart';
import 'widgets/login_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'widgets/login_with_button.dart';
import 'widgets/remember_me_and_forgot_password.dart';
import 'widgets/signup_prompt.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final rememberMeCheckBox = ValueNotifier<bool>(false);

  @override
  void dispose() {
    rememberMeCheckBox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      header: const LoginHeader(),
      children: [
        Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              RememberMeAndForgotPassword(
                rememberMeCheckBox: rememberMeCheckBox,
                onForgotPasswordPressed: () {
                  // Handle forgot password logic here
                },
              ),
              const SizedBox(height: 16),
              LoginPrimaryButton(
                text: 'Login',
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
                // Handle Google login logic here
              },
            ),
            const SizedBox(width: 8),
            LoginWithButton(
              buttonText: 'Facebook',
              buttonIcon: 'assets/images/facebook_icon.png',
              onPressed: () {
                // Handle Facebook login logic here
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        SignupPrompt(onSignUpPressed: () => context.pushNamed(Routes.register)),
      ],
    );
  }
}
