import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/on_repeat_provider.dart';
import 'package:jplayer/src/domain/providers/playlist_songs_source.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/collection_download_button.dart';
import 'package:jplayer/src/presentation/widgets/mix_page_scaffold.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class OnRepeatPage extends ConsumerWidget {
  const OnRepeatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final edgePadding = device.isMobile ? 16.0 : 30.0;
    final isOffline = ref.watch(isOfflineProvider);
    final onRepeat = ref.watch(onRepeatPlaylistProvider);
    final songs = ref.watch(onRepeatSongsProvider);
    final items = songs.valueOrNull ?? const <LibraryItem>[];
    final imageService = ref.read(imageServiceProvider);

    return MixPageScaffold(
      name: onRepeatName,
      subtitle: 'Most played in the last 30 days',
      songs: items,
      coverImages: [if (onRepeat != null) imageService.itemImage(onRepeat)],
      isPlayLoading:
          onRepeat != null && ref.watch(setPlaybackProvider) == onRepeat.id,
      onPlay: () {
        if (onRepeat == null || items.isEmpty) return;
        ref
            .read(setPlaybackProvider.notifier)
            .playSongs(onRepeat, items)
            .ignore();
      },
      onShuffle: () {
        if (onRepeat == null || items.isEmpty) return;
        ref
            .read(setPlaybackProvider.notifier)
            .shufflePlay(onRepeat, () async => items)
            .ignore();
      },
      actions: [
        if (onRepeat != null)
          CollectionDownloadButton(
            item: onRepeat,
            songs: () =>
                ref.read(playlistSongsSourceProvider).songsOf(onRepeat.id),
          ),
      ],
      slivers: [
        ...songs.when(
          data: (list) => [
            if (list.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Nothing played in the last 30 days.'),
                ),
              )
            else
              SongListSliver(
                songs: list,
                set: isOffline ? onRepeat : null,
                showPosition: true,
                edgePadding: edgePadding,
                onItemUpdated: ref
                    .read(onRepeatSongsProvider.notifier)
                    .updateItem,
              ),
          ],
          error: (error, stackTrace) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(error.toString())),
              ),
            ),
          ],
          loading: () => [
            SliverToBoxAdapter(
              child: SongRowsShimmer(
                device: device,
                count: 8,
                edgePadding: edgePadding,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
