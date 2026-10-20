import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/data/storages/account_store.dart';
import 'package:jplayer/src/domain/providers/discovered_servers_provider.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({this.addingServer = false, super.key});

  final bool addingServer;

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
  String? _resolvedProductName;
  bool _resolvedQuickConnect = false;
  String? _probedInput;
  int _probeGeneration = 0;
  List<ServerIdentity> _apiChoices = const [];

  ServerUrlFieldMode _mode = ServerUrlFieldMode.discovering;
  DiscoveredServer? _selectedServer;
  bool _manualEntry = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _serverUrlFocusNode.addListener(_onServerUrlFocusChange);
    _serverUrlInputController.addListener(_onServerUrlChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(serverDiscoveryProvider.notifier).scan());
    });
    if (!widget.addingServer) unawaited(_prefillLastServer());
  }

  Future<void> _prefillLastServer() async {
    final url = await ref.read(lastServerUrlProvider.future);
    if (!mounted || url == null || url.isEmpty) return;
    if (_manualEntry || _serverUrlInputController.text.isNotEmpty) return;
    _serverUrlInputController.text = url;
    unawaited(_probeServer());
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
    final candidate = discovery.servers.firstWhereOrNull(
      (server) => !widget.addingServer || !_isAdded(server.id),
    );
    if (candidate != null) {
      if (_selectedServer == null) _selectServer(candidate);
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
      _apiChoices = const [];
      _resolvedServerUrl = server.serverUrl;
      _resolvedServerType = server.serverType;
      _resolvedProductName = null;
      _resolvedQuickConnect = server.quickConnect;
    });
  }

  String? get _serverProductName =>
      _apiChoices.firstOrNull?.productName ?? _resolvedProductName;

  void _selectApi(ServerIdentity identity) {
    setState(() {
      error = null;
      _applyIdentity(identity);
    });
  }

  void _applyIdentity(ServerIdentity? identity) {
    _resolvedServerUrl = identity?.serverUrl;
    _resolvedServerType = identity?.serverType;
    _resolvedProductName = identity?.productName;
    _resolvedQuickConnect = identity?.quickConnect ?? false;
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
        _apiChoices = const [];
        _applyIdentity(null);
      });
    }

    final result = await ref.read(serverProbeServiceProvider).discover(rawUrl);
    if (!mounted || generation != _probeGeneration) return;

    setState(() {
      _apiChoices = result == null || result.alternateApis.isEmpty
          ? const []
          : [result, ...result.alternateApis];
      _applyIdentity(result);
    });
  }

  void _resetDiscoveredServer() {
    _probeGeneration++;
    _probedInput = null;
    if (_resolvedServerType == null) return;
    setState(() {
      _apiChoices = const [];
      _applyIdentity(null);
    });
  }

  Future<void> signInWithQuickConnect() async {
    if (error != null) setState(() => error = null);

    final serverUrl = _effectiveServerUrl;
    if (serverUrl.isEmpty) {
      setState(() => error = 'Server URL is required');
      return;
    }

    final auth = ref.read(authProvider.notifier);
    final request = await auth.beginQuickConnect(
      serverUrl,
      serverType: _resolvedServerType,
    );
    if (!mounted) return;
    if (request == null) {
      setState(() => error = AuthNotifier.quickConnectUnavailableError);
      return;
    }

    final result = await showAdaptiveDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuickConnectDialog(code: request.code),
    );
    if (!mounted) return;
    if (result == null || result == AuthNotifier.quickConnectCancelled) return;
    setState(() => error = result);
  }

  Future<void> signIn({bool promptForCertificate = true}) async {
    setState(() {
      error = null;
      _submitting = true;
    });

    final credentials = UserCredentials(
      username: _emailInputController.text.trim(),
      pw: _passwordInputController.text.trim(),
      serverUrl: _effectiveServerUrl,
    );
    if (credentials.serverUrl.isEmpty || credentials.username.isEmpty) {
      setState(() {
        error = 'Server URL and login are required';
        _submitting = false;
      });
      return;
    }

    final serverUri = Uri.tryParse(credentials.serverUrl);
    if (serverUri == null || !serverUri.isAbsolute || serverUri.host.isEmpty) {
      setState(() {
        error =
            'Server URL is invalid. Try something like 192.168.1.10:8096 or '
            'jellyfin.example.com';
        _submitting = false;
      });
      return;
    }
    final resp = await ref
        .read(authProvider.notifier)
        .login(
          credentials,
          serverType: _resolvedServerType,
        );
    if (!mounted) return;
    if (resp == null) {
      if (widget.addingServer) context.go('/');
      return;
    }

    if (promptForCertificate && await _trustServerCertificate(serverUri.host)) {
      if (!mounted) return;
      await _reprobeServer();
      if (!mounted) return;
      await signIn(promptForCertificate: false);
      return;
    }
    if (!mounted) return;

    setState(() {
      error = resp;
      _submitting = false;
    });
  }

  Future<bool> _trustServerCertificate(String host) async {
    final trust = ref.read(certificateTrustProvider);
    final certificate = trust.rejectedFor(host);
    if (certificate == null) return false;

    final confirmed = await showAppDialog<bool>(
      context,
      builder: (context) => CertificateTrustDialog(certificate: certificate),
    );
    if (confirmed ?? false) {
      await trust.trust(certificate);
      return true;
    }
    return false;
  }

  Future<void> _reprobeServer() async {
    _probedInput = null;
    await _probeServer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(serverDiscoveryProvider, (_, next) => _onDiscoveryChanged(next));
    return WindowResizeFrame(
      child: Scaffold(
        body: Stack(
          children: [
            _form(),
            if (showsDesktopTitleBar)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DesktopTitleBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return SafeArea(
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
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !_submitting) {
                      signIn();
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoginLogo(
                        serverType: _resolvedServerType,
                        productName: _serverProductName,
                      ),
                      const SizedBox(height: 63),
                      _serverURLField(),
                      const SizedBox(height: 8),
                      _loginField(),
                      const SizedBox(height: 8),
                      _passwordField(),
                      if (error case final message?) ...[
                        const SizedBox(height: 12),
                        _errorText(message),
                      ],
                      const SizedBox(height: 63),
                      _signInButton(),
                      if (widget.addingServer) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: context.pop,
                          child: const Text('Cancel'),
                        ),
                      ] else
                        ?_savedServers(),
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

  bool _isAdded(String? serverId) => ref
      .read(accountsProvider)
      .any((account) => account.serverId == serverId && !account.needsReauth);

  Widget? _savedServers() {
    if (ref.watch(accountsProvider).isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: ServerAccountList(
        removable: false,
        showAdd: false,
        onSelect: _useSavedServer,
      ),
    );
  }

  void _useSavedServer(ServerAccount account) {
    if (!account.needsReauth) {
      unawaited(ref.read(authProvider.notifier).switchTo(account.serverId));
      return;
    }
    _startManualEntry();
    _serverUrlInputController.text = account.url;
    _emailInputController.text = account.userName ?? '';
    _passwordInputController.clear();
    unawaited(_probeServer());
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

  Widget _serverURLField() {
    final footer = _serverFieldFooter();

    return Column(
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
        ?footer,
        ?_apiSelector(),
      ],
    );
  }

  Widget? _serverFieldFooter() {
    if (!_resolvedQuickConnect) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [_quickConnectButton()],
      ),
    );
  }

  Widget? _apiSelector() {
    if (_apiChoices.length < 2) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ServerApiSelector(
        choices: _apiChoices,
        selectedUrl: _resolvedServerUrl,
        onSelect: _selectApi,
      ),
    );
  }

  Widget? _serverUrlSuffixIcon() => (_resolvedServerType != null)
      ? Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.secondary,
          size: 22,
        )
      : null;

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

  Widget _quickConnectButton() => TextButton(
    onPressed: signInWithQuickConnect,
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: Colors.white,
    ),
    child: const Text(
      'Quick Connect',
      style: TextStyle(
        fontFamily: FontFamily.inter,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        decoration: TextDecoration.underline,
        decorationColor: Colors.white,
      ),
    ),
  );

  Widget _signInButton() => ShadowedButton(
    onPressed: _submitting ? null : signIn,
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
