import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/now_playing_queue_view.dart';
import 'package:jplayer/src/presentation/widgets/sidebar_overlay.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

class QueueSidebar extends ConsumerWidget {
  const QueueSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShown =
        ref.watch(queueSidebarVisibleProvider) && ref.watch(hasQueueProvider);

    return SidebarOverlay(
      isShown: isShown,
      title: 'Queue',
      backgroundColor: ref.watch(artworkSchemeProvider).valueOrNull?.surface,
      onClose: () =>
          ref.read(queueSidebarVisibleProvider.notifier).state = false,
      child: NowPlayingQueueView(isActive: isShown),
    );
  }
}
