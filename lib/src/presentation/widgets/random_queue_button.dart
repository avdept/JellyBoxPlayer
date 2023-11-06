import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/providers/player_provider.dart';

class RandomQueueButton extends ConsumerWidget {
  const RandomQueueButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return StreamBuilder<bool>(
      stream: ref.read(playerProvider).shuffleModeEnabledStream,
      builder: (context, snapshot) {
        return IconButton(
          onPressed: () => ref.read(playerProvider).setShuffleModeEnabled(!snapshot.data!),
          icon: Icon(
            JPlayer.mix,
            color: theme.colorScheme.onPrimary,
          ),
          selectedIcon: Icon(
            JPlayer.mix,
            color: theme.colorScheme.primary,
          ),
          isSelected: snapshot.data,
        );
      },
    );
  }
}
