import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/providers/server_capabilities_provider.dart';
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
import 'package:jplayer/src/presentation/widgets/sort_menu_button.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

Map<EntityFilter, String> _sortOptions(BuildContext context) =>
    <EntityFilter, String>{
      EntityFilter.dateLiked: S.of(context).dateLiked,
      EntityFilter.sortName: S.of(context).name,
      EntityFilter.dateCreated: S.of(context).dateAdded,
      EntityFilter.albumArtist: S.of(context).albumArtist,
      EntityFilter.random: S.of(context).random,
    };

class FavouriteSongsPage extends ConsumerStatefulWidget {
  const FavouriteSongsPage({super.key});

  @override
  ConsumerState<FavouriteSongsPage> createState() => _FavouriteSongsPageState();
}

class _FavouriteSongsPageState extends ConsumerState<FavouriteSongsPage> {
  Filter? _chosen;

  Filter _filterFor(MediaServerCapabilities capabilities) {
    final chosen = _chosen;
    if (chosen == null) return defaultLikedSongsFilter(capabilities);
    if (chosen.orderBy == EntityFilter.dateLiked &&
        !capabilities.likedTimestamp) {
      return defaultLikedSongsFilter(capabilities);
    }
    return chosen;
  }

  void _applySort(EntityFilter field, Filter current) {
    setState(() {
      _chosen = current.orderBy == field
          ? current.copyWith(desc: !current.desc)
          : Filter(
              orderBy: field,
              desc:
                  field == EntityFilter.dateCreated ||
                  field == EntityFilter.dateLiked,
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final edgePadding = device.isMobile ? 16.0 : 30.0;
    final capabilities = ref.watch(serverCapabilitiesProvider);
    final filter = _filterFor(capabilities);
    final isOffline = ref.watch(isOfflineProvider);
    final liked = ref.watch(likedSongsPlaylistProvider);
    final songs = isOffline && liked != null
        ? ref.watch(downloadedPlaylistSongsProvider(liked.id))
        : ref
              .watch(favouriteSongsListProvider(filter))
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
      coverImages: [if (liked != null) imageService.itemImage(liked)],
      isPlayLoading:
          liked != null && ref.watch(setPlaybackProvider) == liked.id,
      onPlay: () {
        if (liked == null) return;
        ref
            .read(setPlaybackProvider.notifier)
            .playFavouriteSongs(liked)
            .ignore();
      },
      onShuffle: () {
        if (liked == null) return;
        final playback = ref.read(setPlaybackProvider.notifier);
        playback.shufflePlay(liked, playback.favouriteSongs).ignore();
      },
      onLoadMore: isOffline
          ? null
          : () => ref
                .read(favouriteSongsListProvider(filter).notifier)
                .loadMore(),
      sort: isOffline
          ? null
          : SortMenuButton<EntityFilter>(
              options: {
                for (final entry in _sortOptions(context).entries)
                  if (entry.key != EntityFilter.dateLiked ||
                      capabilities.likedTimestamp)
                    entry.key: entry.value,
              },
              selected: filter.orderBy,
              descending: filter.desc,
              onSelected: (field) => _applySort(field, filter),
            ),
      actions: [
        if (liked != null)
          CollectionDownloadButton(
            item: liked,
            songs: () => fetchAllFavouriteSongs(
              ref.read(mediaServerClientProvider),
              libraryId: ref.read(currentLibraryProvider).valueOrNull?.id,
              sort: filter.orderBy.itemSort,
              direction: sortDirectionOf(descending: filter.desc),
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
                        ? S.of(context).likedSongsNotDownloaded
                        : S.of(context).noSongsYet,
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
                          .read(favouriteSongsListProvider(filter).notifier)
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
