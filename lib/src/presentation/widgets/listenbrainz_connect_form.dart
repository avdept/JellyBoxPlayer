import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/listenbrainz_account_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class ListenBrainzConnectForm extends ConsumerStatefulWidget {
  const ListenBrainzConnectForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  static final Uri tokenPageUri = Uri.parse(
    'https://listenbrainz.org/settings/',
  );

  final EdgeInsets padding;

  @override
  ConsumerState<ListenBrainzConnectForm> createState() =>
      _ListenBrainzConnectFormState();
}

class _ListenBrainzConnectFormState
    extends ConsumerState<ListenBrainzConnectForm> {
  final _tokenController = TextEditingController();
  String? _error;
  var _submitting = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final connected = await ref
        .read(listenBrainzAccountProvider.notifier)
        .connect(_tokenController.text);
    if (!mounted) return;
    if (connected) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _error = ref.read(listenBrainzAccountProvider).error;
    });
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
          const ModalFormHeader('Connect ListenBrainz'),
          const SizedBox(height: 8),
          Text(
            'Paste the user token from your ListenBrainz settings.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            controller: _tokenController,
            placeholder: 'User token',
            obscureText: true,
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => unawaited(
                launchUrl(
                  ListenBrainzConnectForm.tokenPageUri,
                  mode: LaunchMode.externalApplication,
                ),
              ),
              style: ModalFormActions.buttonStyle(context),
              child: const Text('Get your token from listenbrainz.org'),
            ),
          ),
          const SizedBox(height: 16),
          ModalFormActions(
            submitLabel: 'Connect',
            onSubmit: () => unawaited(_submit()),
            busy: _submitting,
          ),
        ],
      ),
    );
  }
}
