import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/data/backend/remote_access.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';

class PluginNoticeBanner extends ConsumerWidget {
  const PluginNoticeBanner({required this.notice, super.key});

  final PluginNotice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimary;
    final message = notice.message ?? S.of(context).pluginOutOfDateNotice;

    return Material(
      color: Colors.amber.withValues(alpha: 0.22),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 3, bottom: 3),
          child: Row(
            children: [
              Icon(Icons.system_update_outlined, size: 16, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    color: foreground,
                  ),
                ),
              ),
              IconButton(
                tooltip: S.of(context).dismiss,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                color: foreground,
                icon: const Icon(Icons.close),
                onPressed: () =>
                    ref.read(dismissedPluginNoticeProvider.notifier).state =
                        notice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
