import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/server_probe_provider.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/current_server_type_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';

class ServerAddressSettings extends ConsumerWidget {
  const ServerAddressSettings({super.key});

  static final ButtonStyle _buttonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _edit(BuildContext context) => unawaited(
    showFormModal<void>(
      context,
      builder: (context) => const RemoteAddressForm(),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(serverAddressesProvider);
    if (addresses == null) return const SizedBox.shrink();
    final remote = addresses.remote;
    final connection = ref.watch(serverConnectionProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        _AddressRow(
          label: 'Home',
          address: addresses.home,
          active: connection == ServerConnection.direct,
          muted: muted,
        ),
        if (remote == null)
          TextButton.icon(
            onPressed: () => _edit(context),
            style: _buttonStyle,
            icon: const Icon(Icons.add_link),
            label: const Text('Add remote address'),
          )
        else
          _AddressRow(
            label: 'Remote',
            address: remote,
            active: connection == ServerConnection.remote,
            muted: muted,
            actions: [
              _ActionIcon(
                icon: Icons.edit_outlined,
                tooltip: 'Change remote address',
                onPressed: () => _edit(context),
              ),
              _ActionIcon(
                icon: Icons.delete_outline,
                tooltip: 'Remove remote address',
                onPressed: () => unawaited(
                  ref.read(connectivityProvider.notifier).setRemote(null),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.label,
    required this.address,
    required this.active,
    required this.muted,
    this.actions = const [],
  });

  final String label;
  final String address;
  final bool active;
  final Color muted;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Row(
      spacing: 8,
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: TextStyle(color: muted)),
        ),
        Flexible(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: active ? FontWeight.w600 : null),
          ),
        ),
        if (active) const Icon(Icons.check, size: 16),
        if (actions.isNotEmpty) Row(spacing: 4, children: actions),
      ],
    ),
  );
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? theme.colorScheme.primary
              : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      ),
      icon: Icon(icon),
    );
  }
}

class RemoteAddressForm extends ConsumerStatefulWidget {
  const RemoteAddressForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  static const differentServerError =
      'That address answers as a different server.';

  final EdgeInsets padding;

  @override
  ConsumerState<RemoteAddressForm> createState() => _RemoteAddressFormState();
}

class _RemoteAddressFormState extends ConsumerState<RemoteAddressForm> {
  late final _controller = TextEditingController(
    text: ref.read(serverAddressesProvider)?.remote ?? '',
  );
  String? _error;
  var _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final text = _controller.text.trim();
    setState(() {
      _submitting = true;
      _error = null;
    });
    final url = text.isEmpty ? null : normalizeServerUrl(text);
    if (url != null && !await _sameServer(url)) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = RemoteAddressForm.differentServerError;
      });
      return;
    }
    await ref.read(connectivityProvider.notifier).setRemote(url);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _sameServer(String url) async {
    final identity = await ref.read(serverProbeServiceProvider).probe(url);
    if (identity == null) return true;
    final serverId = ref.read(currentServerIdProvider);
    final serverType = ref.read(currentServerTypeProvider);
    if (serverType != null && identity.serverType != serverType) return false;
    final id = identity.serverId;
    return serverId == null || id == null || id.isEmpty || id == serverId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      minimum: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalFormHeader('Remote address'),
          const SizedBox(height: 8),
          Text(
            'A second address for the same server, such as a Tailscale, '
            'WireGuard or reverse proxy URL. Jellybox uses the home address '
            'when it answers and switches to this one when it does not.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            controller: _controller,
            placeholder: 'https://jellyfin.example.ts.net:8096',
            keyboardType: TextInputType.url,
            autofocus: true,
            textInputAction: TextInputAction.done,
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          ModalFormActions(
            submitLabel: 'Save',
            onSubmit: () => unawaited(_submit()),
            busy: _submitting,
          ),
        ],
      ),
    );
  }
}
