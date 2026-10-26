import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/presentation/widgets/server_accounts.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimary;

    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.24),
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () => ref.read(connectivityProvider.notifier).refresh(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              children: [
                Icon(Icons.cloud_off_outlined, size: 16, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    S.of(context).offlineOnlyDownloads,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      color: foreground,
                    ),
                  ),
                ),
                if (ref.watch(accountsProvider).length > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () => unawaited(showServerSwitcher(context)),
                      child: Text(
                        S.of(context).switchServer,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                Text(
                  S.of(context).retry,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
