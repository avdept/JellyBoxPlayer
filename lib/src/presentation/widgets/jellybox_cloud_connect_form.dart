import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optional_features/jellybox_cloud.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';

class JellyboxCloudConnectForm extends ConsumerStatefulWidget {
  const JellyboxCloudConnectForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  final EdgeInsets padding;

  @override
  ConsumerState<JellyboxCloudConnectForm> createState() =>
      _JellyboxCloudConnectFormState();
}

class _JellyboxCloudConnectFormState
    extends ConsumerState<JellyboxCloudConnectForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final TextEditingController _address;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: ref.read(conductorUrlProvider));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    if (kDebugMode) ref.read(conductorUrlProvider.notifier).url = _address.text;

    final connected = await ref
        .read(cloudProvider.notifier)
        .signIn(
          address: kDebugMode ? _address.text : ref.read(conductorUrlProvider),
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (connected) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _submitting = false);
  }

  Future<void> _disconnect() async {
    await ref.read(cloudProvider.notifier).signOut();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    final state = ref.watch(cloudProvider);
    final account = state.account;

    return SafeArea(
      top: false,
      minimum: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalFormHeader('Jellybox Cloud'),
          const SizedBox(height: 8),

          if (account != null && !_submitting) ...[
            Text(
              'Connected as ${account.email}',
              style: TextStyle(color: muted),
            ),
            if (_connectionError(ref) case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Current online devices: ${ref.watch(cloudProvider).devices.length}',
                style: TextStyle(color: muted),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => unawaited(_disconnect()),
                style: ModalFormActions.buttonStyle(context),
                child: const Text('Disconnect'),
              ),
            ),
          ] else ...[
            Text(
              'Sign in to play across your devices - start on one, '
              'carry on with another.',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 16),
            Text(
              'Hitting connect will either create new account or sign in to existing account.',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 16),
            if (kDebugMode) ...[
              LabeledTextField(
                controller: _address,
                label: 'Server',
                placeholder: '192.168.1.10:4010',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
            ],
            LabeledTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            LabeledTextField(
              controller: _password,
              label: 'Password',
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            if (state.error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ModalFormActions(
              submitLabel: 'Connect',
              onSubmit: () => unawaited(_submit()),
              busy: _submitting,
            ),
          ],
        ],
      ),
    );
  }

  String? _connectionError(WidgetRef ref) {
    final conductor = ref.watch(cloudProvider);
    if (conductor.status != ConductorStatus.error) return null;
    return conductor.error ?? 'Connection problem';
  }
}
