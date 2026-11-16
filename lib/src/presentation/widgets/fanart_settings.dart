import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/fanart_provider.dart';
import 'package:jplayer/src/presentation/widgets/fanart_keys_form.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';

class FanartSettings extends ConsumerWidget {
  const FanartSettings({super.key});

  static final ButtonStyle _buttonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _openKeysForm(BuildContext context) => unawaited(
    showFormModal<void>(
      context,
      builder: (context) => const FanartKeysForm(),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(fanartAccountProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);

    return switch (account.status) {
      FanartStatus.loading => const SizedBox.shrink(),
      FanartStatus.ownKeys => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              account.credentials.hasOwnKey
                  ? 'Using your own project key'
                  : 'Using Jellybox Link with your personal key',
              style: TextStyle(color: muted),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _openKeysForm(context),
            style: _buttonStyle,
            child: const Text('Change'),
          ),
          TextButton(
            onPressed: () =>
                unawaited(ref.read(fanartAccountProvider.notifier).useLink()),
            style: _buttonStyle,
            child: const Text('Remove keys'),
          ),
        ],
      ),
      FanartStatus.link ||
      FanartStatus.checking ||
      FanartStatus.rejected => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          if (account.status == FanartStatus.rejected)
            if (account.error case final error?)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          TextButton.icon(
            onPressed: account.status == FanartStatus.checking
                ? null
                : () => _openKeysForm(context),
            style: _buttonStyle,
            icon: const Icon(Icons.key),
            label: const Text('Use your own fanart.tv keys'),
          ),
        ],
      ),
    };
  }
}
