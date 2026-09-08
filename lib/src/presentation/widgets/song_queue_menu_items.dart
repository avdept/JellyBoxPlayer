import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

List<PopupMenuEntry<void>> songQueueMenuItems(
  BuildContext context,
  WidgetRef ref,
  LibraryItem song,
) {
  final messenger = ScaffoldMessenger.of(context);
  final playback = ref.read(playbackProvider.notifier);

  void report({required bool queued, required String message}) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(queued ? message : 'Could not queue ${song.name}'),
      ),
    );
  }

  return [
    PopupMenuItem(
      onTap: () => playback
          .playNext(song)
          .then(
            (queued) => report(queued: queued, message: 'Playing next'),
          )
          .ignore(),
      child: const Text('Play next'),
    ),
    PopupMenuItem(
      onTap: () => playback
          .addToQueue(song)
          .then(
            (queued) => report(queued: queued, message: 'Added to queue'),
          )
          .ignore(),
      child: const Text('Add to queue'),
    ),
  ];
}
