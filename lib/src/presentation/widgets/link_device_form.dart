import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';

class LinkDeviceForm extends ConsumerStatefulWidget {
  const LinkDeviceForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  final EdgeInsets padding;

  @override
  ConsumerState<LinkDeviceForm> createState() => _LinkDeviceFormState();
}

class _LinkDeviceFormState extends ConsumerState<LinkDeviceForm> {
  final _code = TextEditingController();
  var _submitting = false;
  String? _linked;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _code.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final device = await ref
        .read(cloudProvider.notifier)
        .approveDevice(_code.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _linked = device;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    final error = ref.watch(cloudProvider.select((state) => state.error));

    return SafeArea(
      top: false,
      minimum: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalFormHeader('Link a TV'),
          const SizedBox(height: 8),
          if (_linked case final linked?) ...[
            Text(
              '$linked is now connected to your account.',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ModalFormActions.buttonStyle(context),
                child: const Text('Done'),
              ),
            ),
          ] else ...[
            Text(
              'On the TV, open Settings and choose Connect under '
              'Jellybox Link. Type the code it shows here.',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              controller: _code,
              label: 'Code',
              placeholder: 'ABCD-EFGH',
              autofocus: true,
              textInputAction: TextInputAction.done,
            ),
            if (error case final error?)
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
              submitLabel: 'Link',
              onSubmit: () => unawaited(_submit()),
              busy: _submitting,
            ),
          ],
        ],
      ),
    );
  }
}
