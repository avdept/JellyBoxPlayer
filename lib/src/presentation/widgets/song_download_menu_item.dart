import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

Future<void> toggleSongDownload(
  DownloadManagerNotifier manager,
  LibraryItem song,
) async {
  if (await manager.isSongDownloaded(song.id)) {
    await manager.deleteSong(song.id);
  } else {
    await manager.downloadSong(song);
  }
}

PopupMenuItem<void> songDownloadMenuItem(WidgetRef ref, LibraryItem song) =>
    PopupMenuItem(
      onTap: () => toggleSongDownload(
        ref.read(downloadManagerProvider.notifier),
        song,
      ).ignore(),
      child: _SongDownloadLabel(song: song),
    );

class _SongDownloadLabel extends ConsumerWidget {
  const _SongDownloadLabel({required this.song});

  final LibraryItem song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded =
        ref.watch(isSongDownloadedProvider(song)).valueOrNull ?? false;
    return Text(isDownloaded ? 'Remove download' : 'Download');
  }
}

class SongDownloadListTile extends ConsumerWidget {
  const SongDownloadListTile({required this.song, this.onSelected, super.key});

  final LibraryItem song;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded =
        ref.watch(isSongDownloadedProvider(song)).valueOrNull ?? false;
    return ListTile(
      leading: Icon(isDownloaded ? Icons.delete_outline : JPlayer.download),
      title: Text(isDownloaded ? 'Remove download' : 'Download'),
      onTap: () {
        final manager = ref.read(downloadManagerProvider.notifier);
        onSelected?.call();
        toggleSongDownload(manager, song).ignore();
      },
    );
  }
}
