import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class PlayerTime extends ConsumerWidget {
  const PlayerTime({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(playerTimeDisplayProvider);
    final (seconds, duration) = ref.watch(
      barProgressProvider.select(
        (progress) => (progress.position.inSeconds, progress.duration),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref
            .read(appSettingsProvider.notifier)
            .setValue(AppSetting.playerTimeDisplay, display.next.name),
        child: Text(
          playerTimeLabel(
            display,
            position: Duration(seconds: seconds),
            duration: duration,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
