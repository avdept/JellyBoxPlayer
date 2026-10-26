import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';
import 'package:jplayer/src/presentation/widgets/now_playing_queue_view.dart';
import 'package:jplayer/src/presentation/widgets/sidebar_overlay.dart';

class QueueSidebar extends ConsumerWidget {
  const QueueSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShown = ref.watch(queueSidebarVisibleProvider);
    final hasQueue = ref.watch(barHasQueueProvider);

    return SidebarOverlay(
      isShown: isShown,
      title: S.of(context).queue,
      actions: [
        HoverIconButton(
          onPressed: hasQueue
              ? () => ref.read(playbackProvider.notifier).clearQueue()
              : null,
          color: Theme.of(context).colorScheme.onPrimary,
          tooltip: S.of(context).clearQueue,
          icon: const Icon(Icons.playlist_remove),
        ),
      ],
      onClose: () =>
          ref.read(queueSidebarVisibleProvider.notifier).state = false,
      child: hasQueue
          ? NowPlayingQueueView(isActive: isShown)
          : Center(child: Text(S.of(context).nothingInQueue)),
    );
  }
}
