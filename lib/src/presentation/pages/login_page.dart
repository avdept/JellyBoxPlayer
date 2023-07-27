import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(vertical: 36, horizontal: 48),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 440,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(Images.mainLogo),
                      const SizedBox(height: 63),
                      _serverURLField(),
                      const SizedBox(height: 8),
                      _loginField(),
                      const SizedBox(height: 8),
                      _passwordField(),
                      const SizedBox(height: 63),
                      _signInButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _serverURLField() => const LabeledTextField(
        label: 'Server URL',
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.next,
      );

  Widget _loginField() => const LabeledTextField(
        label: 'Login',
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
      );

  Widget _passwordField() => const LabeledTextField(
        label: 'Password',
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
      );

  Widget _signInButton() => InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(36),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 74),
          decoration: BoxDecoration(
            color: const Color(0xFF404C6C),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                offset: const Offset(-1, 3),
                color: const Color(0xFF404C6C).withOpacity(0.7),
                spreadRadius: 4,
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            'Sign in',
            style: TextStyle(
              fontFamily: FontFamily.inter,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
