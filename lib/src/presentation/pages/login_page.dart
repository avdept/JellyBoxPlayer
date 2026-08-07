import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
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
  final _serverUrlFocusNode = FocusNode();

  ServerProbeResult? _discoveredServer;
  String? _probedInput;
  int _probeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _serverUrlFocusNode.addListener(_onServerUrlFocusChange);
    _serverUrlInputController.addListener(_onServerUrlChanged);
  }

  @override
  void dispose() {
    _serverUrlFocusNode
      ..removeListener(_onServerUrlFocusChange)
      ..dispose();
    _serverUrlInputController
      ..removeListener(_onServerUrlChanged)
      ..dispose();
    _emailInputController.dispose();
    _passwordInputController.dispose();
    super.dispose();
  }

  void _onServerUrlFocusChange() {
    if (!_serverUrlFocusNode.hasFocus) unawaited(_probeServer());
  }

  void _onServerUrlChanged() {
    if (_probedInput == null) return;
    if (_serverUrlInputController.text.trim() == _probedInput) return;
    _resetDiscoveredServer();
  }

  Future<void> _probeServer() async {
    final rawUrl = _serverUrlInputController.text.trim();
    if (rawUrl.isEmpty) {
      _resetDiscoveredServer();
      return;
    }
    if (rawUrl == _probedInput) return;

    final generation = ++_probeGeneration;
    _probedInput = rawUrl;
    if (_discoveredServer != null) {
      setState(() => _discoveredServer = null);
    }

    final result = await ref.read(serverProbeServiceProvider).discover(rawUrl);
    if (!mounted || generation != _probeGeneration) return;

    setState(() => _discoveredServer = result);
  }

  void _resetDiscoveredServer() {
    _probeGeneration++;
    _probedInput = null;
    if (_discoveredServer == null) return;
    setState(() => _discoveredServer = null);
  }

  Future<void> signIn() async {
    if (error != null) setState(() => error = null);

    final rawServerUrl = _serverUrlInputController.text.trim();
    final credentials = UserCredentials(
      username: _emailInputController.text.trim(),
      pw: _passwordInputController.text.trim(),
      serverUrl: rawServerUrl.isEmpty
          ? ''
          : _discoveredServer?.serverUrl ?? normalizeServerUrl(rawServerUrl),
    );
    if (credentials.serverUrl.isEmpty || credentials.username.isEmpty) {
      setState(() {
        error = 'Server URL and login are required';
      });
      return;
    }

    final serverUri = Uri.tryParse(credentials.serverUrl);
    if (serverUri == null || !serverUri.isAbsolute || serverUri.host.isEmpty) {
      setState(() {
        error =
            'Server URL is invalid. Try something like 192.168.1.10:8096 or '
            'jellyfin.example.com';
      });
      return;
    }
    final resp = await ref.read(authProvider.notifier).login(credentials);
    if (resp != null && mounted) {
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
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          const SizedBox(height: 12),
                          _errorText(error!),
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

  Widget _errorText(String message) => Text(
    message,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: FontFamily.inter,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.error,
    ),
  );

  Widget _serverURLField() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LabeledTextField(
        label: 'Server URL',
        keyboardType: TextInputType.url,
        controller: _serverUrlInputController,
        focusNode: _serverUrlFocusNode,
        textInputAction: TextInputAction.next,
        suffixIcon: _serverUrlSuffixIcon(),
      ),
      if (_discoveredServer != null) _discoveredServerText(_discoveredServer!),
    ],
  );

  Widget? _serverUrlSuffixIcon() => (_discoveredServer != null)
      ? Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.secondary,
          size: 22,
        )
      : null;

  Widget _discoveredServerText(ServerProbeResult server) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      'Discovered: ${server.info.serverName ?? 'Jellyfin server'}',
      style: TextStyle(
        fontFamily: FontFamily.inter,
        fontSize: 12,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
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
