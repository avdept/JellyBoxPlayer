import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class OfflineNotice extends ConsumerWidget {
  const OfflineNotice({
    required this.message,
    this.onRetry,
    this.showDownloadsLink = false,
    super.key,
  });

  final String message;
  final FutureOr<void> Function()? onRetry;
  final bool showDownloadsLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOffline = ref.watch(isOfflineProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.cloud_off_outlined : Icons.error_outline,
            size: 32,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.3),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () async {
                  await ref.read(connectivityProvider.notifier).refresh();
                  await onRetry?.call();
                },
                child: const Text('Try again'),
              ),
              if (showDownloadsLink)
                TextButton(
                  onPressed: () => context.goNamed(Routes.downloads.name),
                  child: const Text('Open downloads'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
