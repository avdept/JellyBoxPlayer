import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/lidarr_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';

class LidarrConnectForm extends ConsumerStatefulWidget {
  const LidarrConnectForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  final EdgeInsets padding;

  @override
  ConsumerState<LidarrConnectForm> createState() => _LidarrConnectFormState();
}

class _LidarrConnectFormState extends ConsumerState<LidarrConnectForm> {
  late final _urlController = TextEditingController(
    text: ref.read(lidarrAccountProvider).url,
  );
  final _apiKeyController = TextEditingController();
  String? _error;
  var _submitting = false;

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final connected = await ref
        .read(lidarrAccountProvider.notifier)
        .connect(_urlController.text, _apiKeyController.text);
    if (!mounted) return;
    if (connected) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _error = ref.read(lidarrAccountProvider).error;
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
          const ModalFormHeader('Connect Lidarr'),
          const SizedBox(height: 8),
          Text(
            'The API key is under Settings > General in Lidarr.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            controller: _urlController,
            label: 'Server address',
            placeholder: 'http://lidarr.home:8686',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          LabeledTextField(
            controller: _apiKeyController,
            label: 'API key',
            placeholder: 'API key',
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
