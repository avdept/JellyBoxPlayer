import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';

class RandomQueueButton extends ConsumerWidget {
  const RandomQueueButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final queueState = ref.watch(audioQueueProvider);
    return IconButton(
      onPressed: () => ref.read(audioQueueProvider.notifier).toggleShuffle(),
      icon: Icon(
        JPlayer.mix,
        color: theme.colorScheme.onPrimary,
      ),
      selectedIcon: Icon(
        JPlayer.mix,
        color: theme.colorScheme.primary,
      ),
      isSelected: queueState.isShuffled,
    );
  }
}
