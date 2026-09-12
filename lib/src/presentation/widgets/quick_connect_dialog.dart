import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/presentation/widgets/adaptive_dialog_action.dart';
import 'package:jplayer/src/providers/auth_provider.dart';

class QuickConnectDialog extends ConsumerStatefulWidget {
  const QuickConnectDialog({required this.code, super.key});

  final String code;

  @override
  ConsumerState<QuickConnectDialog> createState() => _QuickConnectDialogState();
}

class _QuickConnectDialogState extends ConsumerState<QuickConnectDialog> {
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    unawaited(_awaitApproval());
  }

  Future<void> _awaitApproval() async {
    final result = await ref.read(authProvider.notifier).awaitQuickConnect();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop(result);
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  void _cancel() {
    ref.read(authProvider.notifier).cancelQuickConnect();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop(AuthNotifier.quickConnectCancelled);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog.adaptive(
      title: const Text('Quick Connect'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'On a device where you are already signed in, open Quick Connect '
            'in your user settings and enter this code.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _copyCode,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.code,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _copied ? 'Copied' : 'Tap the code to copy it',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Waiting for approval',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AdaptiveDialogAction(
          onPressed: _cancel,
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
