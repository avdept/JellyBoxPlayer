import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/fanart/fanart_client.dart';
import 'package:jplayer/src/domain/providers/fanart_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class FanartKeysForm extends ConsumerStatefulWidget {
  const FanartKeysForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  final EdgeInsets padding;

  @override
  ConsumerState<FanartKeysForm> createState() => _FanartKeysFormState();
}

class _FanartKeysFormState extends ConsumerState<FanartKeysForm> {
  late final _apiKeyController = TextEditingController(
    text: ref.read(fanartAccountProvider).credentials.apiKey,
  );
  late final _clientKeyController = TextEditingController(
    text: ref.read(fanartAccountProvider).credentials.clientKey,
  );
  String? _error;
  var _submitting = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _clientKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final saved = await ref
        .read(fanartAccountProvider.notifier)
        .useKeys(
          apiKey: _apiKeyController.text,
          clientKey: _clientKeyController.text,
        );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _error = ref.read(fanartAccountProvider).error;
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
          const ModalFormHeader('Your fanart.tv keys'),
          const SizedBox(height: 8),
          Text(
            'Both are optional. With a project key JellyBox talks to '
            'fanart.tv directly instead of going through Jellybox Link. A '
            'personal key from your fanart.tv profile shows new images '
            'sooner. Leave both empty to go back to Jellybox Link.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            controller: _apiKeyController,
            label: 'Project API key',
            placeholder: 'Project API key',
            autofocus: true,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          LabeledTextField(
            controller: _clientKeyController,
            label: 'Personal key',
            placeholder: 'Personal key',
            obscureText: true,
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => unawaited(
                  launchUrl(
                    FanartClient.apiKeyUri,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                style: ModalFormActions.buttonStyle(context),
                child: const Text('Get keys on fanart.tv'),
              ),
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
