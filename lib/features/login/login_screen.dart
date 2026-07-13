import 'package:flutter/material.dart';

import 'widgets/auth_divider.dart';
import 'widgets/login_header.dart';
import 'widgets/login_primary_button.dart';
import 'widgets/login_text_field.dart';
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const LoginHeader(),
              const SizedBox(height: 20),
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LoginTextField(
                      label: 'Email',
                      hintText: 'example@gmail.com',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    const LoginTextField(
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
                        // Handle login logic here
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const AuthDivider(text: 'Or login with'),
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
              SignupPrompt(
                onSignUpPressed: () {
                  // Handle sign up navigation here
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
