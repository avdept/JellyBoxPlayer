import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/lastfm_account_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/lastfm_connect_form.dart';

class LastFmSettings extends ConsumerWidget {
  const LastFmSettings({super.key});

  static final ButtonStyle _buttonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _openConnectForm(BuildContext context) => unawaited(
    showFormModal<void>(
      context,
      builder: (context) => const LastFmConnectForm(),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(lastFmAccountProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);

    return switch (account.status) {
      LastFmStatus.loading => const SizedBox.shrink(),
      LastFmStatus.connected => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Connected as ${account.userName}',
              style: TextStyle(color: muted),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => unawaited(
              ref.read(lastFmAccountProvider.notifier).disconnect(),
            ),
            style: _buttonStyle,
            child: const Text('Disconnect'),
          ),
        ],
      ),
      LastFmStatus.disconnected ||
      LastFmStatus.authorizing ||
      LastFmStatus.connecting ||
      LastFmStatus.sessionRejected => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          if (account.status == LastFmStatus.sessionRejected)
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
            onPressed: account.status == LastFmStatus.connecting
                ? null
                : () => _openConnectForm(context),
            style: _buttonStyle,
            icon: const Icon(Icons.link),
            label: const Text('Connect Last.fm'),
          ),
        ],
      ),
    };
  }
}
