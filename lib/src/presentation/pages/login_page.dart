import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/discovered_servers_provider.dart';
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

  String? _resolvedServerUrl;
  ServerType? _resolvedServerType;
  String? _probedInput;
  int _probeGeneration = 0;

  ServerUrlFieldMode _mode = ServerUrlFieldMode.discovering;
  DiscoveredServer? _selectedServer;
  bool _manualEntry = false;

  @override
  void initState() {
    super.initState();
    _serverUrlFocusNode.addListener(_onServerUrlFocusChange);
    _serverUrlInputController.addListener(_onServerUrlChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(serverDiscoveryProvider.notifier).scan());
    });
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
    final text = _serverUrlInputController.text.trim();
    if (!_manualEntry && text.isNotEmpty) _startManualEntry();
    if (_probedInput == null) return;
    if (text == _probedInput) return;
    _resetDiscoveredServer();
  }

  void _startManualEntry() {
    ref.read(serverDiscoveryProvider.notifier).cancel();
    _manualEntry = true;
    setState(() {
      _mode = ServerUrlFieldMode.manual;
      _selectedServer = null;
    });
  }

  void _onDiscoveryChanged(ServerDiscoveryState discovery) {
    if (_manualEntry) return;
    if (discovery.servers.isNotEmpty) {
      if (_selectedServer == null) _selectServer(discovery.servers.first);
      return;
    }
    if (discovery.finished && _mode == ServerUrlFieldMode.discovering) {
      setState(() => _mode = ServerUrlFieldMode.manual);
    }
  }

  void _selectServer(DiscoveredServer server) {
    setState(() {
      error = null;
      _selectedServer = server;
      _mode = ServerUrlFieldMode.selected;
      _resolvedServerUrl = server.serverUrl;
      _resolvedServerType = server.serverType;
    });
  }

  void _editSelectedServer() {
    final server = _selectedServer;
    ref.read(serverDiscoveryProvider.notifier).cancel();
    _manualEntry = true;
    _probedInput = server?.serverUrl;
    if (server != null) _serverUrlInputController.text = server.serverUrl;
    setState(() {
      _selectedServer = null;
      _mode = ServerUrlFieldMode.manual;
    });
    _serverUrlFocusNode.requestFocus();
  }

  String get _effectiveServerUrl {
    final server = _selectedServer;
    if (server != null) return server.serverUrl;
    final raw = _serverUrlInputController.text.trim();
    if (raw.isEmpty) return '';
    return _resolvedServerUrl ?? normalizeServerUrl(raw);
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
    if (_resolvedServerType != null) {
      setState(() {
        _resolvedServerUrl = null;
        _resolvedServerType = null;
      });
    }

    final result = await ref.read(serverProbeServiceProvider).discover(rawUrl);
    if (!mounted || generation != _probeGeneration) return;

    setState(() {
      _resolvedServerUrl = result?.serverUrl;
      _resolvedServerType = result?.serverType;
    });
  }

  void _resetDiscoveredServer() {
    _probeGeneration++;
    _probedInput = null;
    if (_resolvedServerType == null) return;
    setState(() {
      _resolvedServerUrl = null;
      _resolvedServerType = null;
    });
  }

  Future<void> signIn() async {
    if (error != null) setState(() => error = null);

    final credentials = UserCredentials(
      username: _emailInputController.text.trim(),
      pw: _passwordInputController.text.trim(),
      serverUrl: _effectiveServerUrl,
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
    final resp = await ref
        .read(authProvider.notifier)
        .login(
          credentials,
          serverType: _resolvedServerType,
        );
    if (resp != null && mounted) {
      setState(() {
        error = resp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(serverDiscoveryProvider, (_, next) => _onDiscoveryChanged(next));
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
                        LoginLogo(
                          serverType: _resolvedServerType,
                        ),
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
      ServerUrlField(
        mode: _mode,
        controller: _serverUrlInputController,
        focusNode: _serverUrlFocusNode,
        servers: ref.watch(serverDiscoveryProvider).servers,
        scanning: ref.watch(serverDiscoveryProvider).scanning,
        selected: _selectedServer,
        onEdit: _editSelectedServer,
        onSelect: _selectServer,
        suffixIcon: _serverUrlSuffixIcon(),
      ),
      if (_mode != ServerUrlFieldMode.selected && _resolvedServerType != null)
        _discoveredServerText(_resolvedServerType!),
    ],
  );

  Widget? _serverUrlSuffixIcon() => (_resolvedServerType != null)
      ? Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.secondary,
          size: 22,
        )
      : null;

  Widget _discoveredServerText(ServerType serverType) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      'Discovered: ${serverType.label} server',
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
