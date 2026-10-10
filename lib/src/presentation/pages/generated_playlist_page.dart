import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playlist_songs_source.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/mix_page_scaffold.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/collection_download_button.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class GeneratedPlaylistPage extends ConsumerWidget {
  const GeneratedPlaylistPage({required this.playlist, super.key});

  final LibraryItem playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final edgePadding = device.isMobile ? 16.0 : 30.0;
    final isOffline = ref.watch(isOfflineProvider);
    final today = ref.watch(todaysPlaylistSongsProvider(playlist.id));
    final downloaded = ref.watch(downloadedPlaylistSongsProvider(playlist.id));
    final items =
        today.valueOrNull ?? downloaded.valueOrNull ?? const <LibraryItem>[];
    final coverSongs = ref
        .watch(todaysPlaylistsProvider)
        .valueOrNull
        ?.firstWhereOrNull((candidate) => candidate.item.id == playlist.id)
        ?.coverSongs;
    final imageService = ref.read(imageServiceProvider);
    final isLoading = today.isLoading || downloaded.isLoading;

    return MixPageScaffold(
      name: playlist.name,
      songs: items,
      coverImages: [
        for (final song in (coverSongs ?? items).take(4))
          imageService.itemImage(song),
      ],
      isPlayLoading: ref.watch(setPlaybackProvider) == playlist.id,
      onPlay: () => ref
          .read(setPlaybackProvider.notifier)
          .playGeneratedPlaylist(playlist)
          .ignore(),
      actions: [
        CollectionDownloadButton(
          item: playlist,
          songs: () =>
              ref.read(playlistSongsSourceProvider).songsOf(playlist.id),
        ),
      ],
      slivers: [
        if (items.isNotEmpty)
          SongListSliver(
            songs: items,
            set: today.hasValue ? null : playlist,
            showPosition: true,
            edgePadding: edgePadding,
            onItemUpdated: today.hasValue
                ? ref
                      .read(todaysPlaylistSongsProvider(playlist.id).notifier)
                      .updateItem
                : (_) {},
          )
        else if (isLoading)
          SliverToBoxAdapter(
            child: SongRowsShimmer(
              device: device,
              count: 8,
              edgePadding: edgePadding,
            ),
          )
        else if (isOffline)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: edgePadding),
              child: OfflineNotice(
                message: "You're offline, so playlists need a connection.",
                onRetry: () =>
                    ref.invalidate(todaysPlaylistSongsProvider(playlist.id)),
                showDownloadsLink: true,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  today.error?.toString() ?? 'This playlist has no songs yet.',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
