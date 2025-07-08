import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => LoginPageState();
}

class LoginPageState extends ConsumerState<LoginPage> {
  String? error;
  final _serverUrlInputController = TextEditingController();
  final _emailInputController = TextEditingController();
  final _passwordInputController = TextEditingController();

  Future<void> signIn() async {
    final credentials = UserCredentials(
      username: _emailInputController.text.trim(),
      pw: _passwordInputController.text.trim(),
      serverUrl: _serverUrlInputController.text.trim(),
    );
    if (credentials.serverUrl.isEmpty || credentials.username.isEmpty) {
      setState(() {
        error = 'Server URL and login are required';
      });
      return;
    }

    if (!Uri.parse(credentials.serverUrl).isAbsolute) {
      setState(() {
        error =
            'Server URL is invalid. Should start with http/https and does not contain any path or query parameters';
      });
      return;
    }
    final resp = await ref.read(authProvider.notifier).login(credentials);
    if (resp != null) {
      setState(() {
        error = resp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(vertical: 36, horizontal: 48),
        child: Center(
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: 440,
                    ),
                    child: IntrinsicHeight(
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event.logicalKey == LogicalKeyboardKey.enter) {
                            signIn();
                          }
                        },
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
                            if (error != null) ...[
                              const SizedBox(height: 8),
                              Text(error!),
                            ],
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
      ),
    );
  }

  Widget _serverURLField() => LabeledTextField(
    label: 'Server URL',
    keyboardType: TextInputType.url,
    controller: _serverUrlInputController,
    textInputAction: TextInputAction.next,
  );

  Widget _loginField() => LabeledTextField(
    label: 'Login',
    keyboardType: TextInputType.text,
    controller: _emailInputController,
    textInputAction: TextInputAction.next,
  );

  Widget _passwordField() => LabeledTextField(
    label: 'Password',
    controller: _passwordInputController,
    obscureText: true,
    keyboardType: TextInputType.visiblePassword,
    textInputAction: TextInputAction.done,
  );

  Widget _signInButton() => ShadowedButton(
    onPressed: signIn,
    child: const Text(
      'Sign in',
      style: TextStyle(
        fontFamily: FontFamily.inter,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
