import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';

class ManualOfflineBanner extends ConsumerWidget {
  const ManualOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimary;
    final style = TextStyle(fontSize: 13, height: 1.2, color: foreground);

    return Material(
      color: Themes.red.colorScheme.primary.withValues(alpha: 0.32),
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () => ref
              .read(appSettingsProvider.notifier)
              .setEnabled(AppSetting.manualOffline, value: false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              children: [
                Icon(Icons.wifi_off, size: 16, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("You're in manual offline mode", style: style),
                ),
                Text(
                  'Turn off',
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
