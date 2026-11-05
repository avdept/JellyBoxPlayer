import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';

class OfflineModeButton extends ConsumerWidget {
  const OfflineModeButton({this.iconSize = 28, super.key});

  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(manualOfflineProvider);
    final red = Themes.red.colorScheme.primary;
    return HoverIconButton(
      icon: Icon(offline ? Icons.wifi_off : Icons.wifi),
      iconSize: iconSize,
      color: offline ? red : null,
      hoverColor: offline ? red : null,
      tooltip: offline ? 'Leave offline mode' : 'Go offline',
      onPressed: () => ref
          .read(appSettingsProvider.notifier)
          .setEnabled(AppSetting.manualOffline, value: !offline),
    );
  }
}
