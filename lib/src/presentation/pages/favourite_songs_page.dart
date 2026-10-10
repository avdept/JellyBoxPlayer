import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/playlist_songs_source.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/mix_page_scaffold.dart';
import 'package:jplayer/src/presentation/widgets/collection_download_button.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

const _sortOptions = <EntityFilter, String>{
  EntityFilter.sortName: 'Name',
  EntityFilter.dateCreated: 'Date Added',
  EntityFilter.albumArtist: 'Album Artist',
  EntityFilter.random: 'Random',
};

class FavouriteSongsPage extends ConsumerStatefulWidget {
  const FavouriteSongsPage({super.key});

  @override
  ConsumerState<FavouriteSongsPage> createState() => _FavouriteSongsPageState();
}

class _FavouriteSongsPageState extends ConsumerState<FavouriteSongsPage> {
  var _filter = const Filter(orderBy: EntityFilter.sortName);

  void _applySort(EntityFilter field) {
    setState(() {
      _filter = _filter.orderBy == field
          ? _filter.copyWith(desc: !_filter.desc)
          : Filter(orderBy: field, desc: field == EntityFilter.dateCreated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final edgePadding = device.isMobile ? 16.0 : 30.0;
    final isOffline = ref.watch(isOfflineProvider);
    final liked = ref.watch(likedSongsPlaylistProvider);
    final songs = isOffline && liked != null
        ? ref.watch(downloadedPlaylistSongsProvider(liked.id))
        : ref
              .watch(favouriteSongsListProvider(_filter))
              .whenData((page) => page.items);
    final items = songs.valueOrNull ?? const <LibraryItem>[];
    final total = isOffline
        ? null
        : ref.watch(favouriteSongsProvider).valueOrNull?.totalRecordCount;
    final imageService = ref.read(imageServiceProvider);

    return MixPageScaffold(
      name: likedSongsName,
      songs: items,
      songCount: total,
      coverImages: [
        for (final song in items.take(4)) imageService.itemImage(song),
      ],
      isPlayLoading:
          liked != null && ref.watch(setPlaybackProvider) == liked.id,
      onPlay: () {
        if (liked == null) return;
        ref
            .read(setPlaybackProvider.notifier)
            .playFavouriteSongs(liked)
            .ignore();
      },
      onLoadMore: isOffline
          ? null
          : () => ref
                .read(favouriteSongsListProvider(_filter).notifier)
                .loadMore(),
      navTrailing: isOffline ? null : _sortButton(),
      actions: [
        if (liked != null)
          CollectionDownloadButton(
            item: liked,
            songs: () => fetchAllFavouriteSongs(
              ref.read(mediaServerClientProvider),
              libraryId: ref.read(currentLibraryProvider).valueOrNull?.id,
              sort: _filter.orderBy.itemSort,
              direction: sortDirectionOf(descending: _filter.desc),
            ),
          ),
      ],
      slivers: [
        ...songs.when(
          data: (list) => [
            if (list.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    isOffline
                        ? 'Liked songs are not downloaded.'
                        : "There's no songs yet.",
                  ),
                ),
              )
            else
              SongListSliver(
                songs: list,
                set: isOffline ? liked : null,
                showPosition: true,
                edgePadding: edgePadding,
                onItemUpdated: isOffline
                    ? (_) {}
                    : ref
                          .read(favouriteSongsListProvider(_filter).notifier)
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

  Widget _sortButton() => PopupMenuButton<EntityFilter>(
    icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.onPrimary),
    tooltip: 'Sort',
    onSelected: _applySort,
    itemBuilder: (context) => [
      for (final entry in _sortOptions.entries)
        PopupMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Expanded(child: Text(entry.value)),
              if (_filter.orderBy == entry.key)
                Icon(
                  _filter.desc ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 18,
                ),
            ],
          ),
        ),
    ],
  );
}
