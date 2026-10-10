import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';
import 'package:jplayer/src/domain/providers/playlist_songs_source.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/mix_page_scaffold.dart';
import 'package:jplayer/src/presentation/widgets/collection_download_button.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class InstantMixPage extends ConsumerStatefulWidget {
  const InstantMixPage({required this.mix, super.key});

  final LibraryItem mix;

  @override
  ConsumerState<InstantMixPage> createState() => _InstantMixPageState();
}

class _InstantMixPageState extends ConsumerState<InstantMixPage> {
  @override
  void initState() {
    super.initState();
    ref.read(instantMixesProvider.notifier).refresh(widget.mix.id).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final mixId = widget.mix.id;
    final mix = ref.watch(
      instantMixesProvider.select(
        (mixes) => mixes.where((mix) => mix.item.id == mixId).firstOrNull,
      ),
    );
    final downloaded = mix == null
        ? ref.watch(downloadedPlaylistSongsProvider(mixId))
        : null;
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final songs =
        mix?.songs ?? downloaded?.valueOrNull ?? const <LibraryItem>[];
    final imageService = ref.read(imageServiceProvider);
    final isLoading = mix == null && (downloaded?.isLoading ?? false);

    return MixPageScaffold(
      name: widget.mix.name,
      subtitle: mix == null || isSoundMixSeed(mix.seed)
          ? null
          : 'Based on ${mix.seed.name}',
      songs: songs,
      coverImages: [
        for (final song in songs.take(4)) imageService.itemImage(song),
      ],
      isPlayLoading: ref.watch(setPlaybackProvider) == mixId,
      onPlay: () {
        final playback = ref.read(setPlaybackProvider.notifier);
        if (mix != null) {
          playback.playInstantMix(mix).ignore();
        } else if (songs.isNotEmpty) {
          playback.playPlaylist(widget.mix).ignore();
        }
      },
      actions: [
        CollectionDownloadButton(
          item: widget.mix,
          songs: () async => songs,
        ),
      ],
      slivers: [
        if (songs.isEmpty && !isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('This mix is no longer available')),
          )
        else
          SongListSliver(
            songs: songs,
            set: widget.mix,
            showPosition: true,
            edgePadding: device.isMobile ? 16 : 30,
            onItemUpdated: (song) =>
                ref.read(instantMixesProvider.notifier).updateSong(mixId, song),
          ),
      ],
    );
  }
}
