import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/platform/tv_home_channel.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/cover_mosaic.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/resume_set_button.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class TvHomePage extends ConsumerStatefulWidget {
  const TvHomePage({super.key});

  @override
  ConsumerState<TvHomePage> createState() => _TvHomePageState();
}

class _TvHomePageState extends ConsumerState<TvHomePage> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<List<LibraryItem>>>(
      recentlyAddedAlbumsProvider,
      (_, albums) {
        final list = albums.valueOrNull;
        if (list == null) return;
        unawaited(
          TvHomeChannel.publishRecentlyAdded(
            list,
            ref.read(imageServiceProvider),
          ),
        );
      },
      fireImmediately: true,
    );
    ref.listenManual(
      contentUpdateIntervalProvider,
      (_, interval) => _scheduleUpdates(interval),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _scheduleUpdates(ContentUpdateInterval interval) {
    _updateTimer?.cancel();
    final duration = interval.duration;
    if (duration == null) return;
    _updateTimer = Timer.periodic(duration, (_) {
      if (!ref.read(isOfflineProvider)) ref.refreshHomeSections();
    });
  }

  ImageProvider _image(LibraryItem item) =>
      ref.read(imageServiceProvider).itemImage(item, size: 400);

  void _openAlbum(LibraryItem album) {
    unawaited(
      context.pushNamed(
        branchAwareName(context, Routes.album),
        extra: {'album': album},
      ),
    );
  }

  void _openPlaylist(LibraryItem playlist) {
    if (isLikedSongsId(playlist.id)) {
      unawaited(
        context.pushNamed(branchAwareName(context, Routes.favouriteSongs)),
      );
      return;
    }
    if (isOnRepeatId(playlist.id)) {
      unawaited(context.pushNamed(branchAwareName(context, Routes.onRepeat)));
      return;
    }
    ref.read(currentPlaylistProvider.notifier).setPlaylist(playlist);
    unawaited(
      context.pushNamed(
        branchAwareName(context, Routes.playlist),
        extra: {'playlist': playlist},
      ),
    );
  }

  void _openGenerated(LibraryItem playlist) => unawaited(
    context.pushNamed(
      Routes.homeGeneratedPlaylist.name,
      extra: {'playlist': playlist},
    ),
  );

  Future<void> _playInstantMix(LibraryItem item) async {
    final mix = ref.read(instantMixesProvider.notifier).byId(item.id);
    if (mix == null) return;
    ref.read(instantMixesProvider.notifier).touch(item.id);
    await ref.read(setPlaybackProvider.notifier).playInstantMix(mix);
  }

  void _onRecentlyPlayed(LibraryItem item) => isInstantMixId(item.id)
      ? unawaited(_playInstantMix(item))
      : _openAlbum(item);

  void _resume(LibraryItem item) {
    final point = ref.read(resumePointProvider(item.id));
    if (point == null) return;
    unawaited(resumeSet(context, ref, point));
  }

  void _onFavourite(LibraryItem item) =>
      item.kind == ItemKind.playlist ? _openPlaylist(item) : _openAlbum(item);

  void Function(LibraryItem) _options(ProviderOrFamily provider) =>
      (item) => unawaited(
        showTvItemOptions(
          context,
          ref,
          item,
          scope: ContextMenuScope.browse,
          onLike: (item) async {
            await toggleFavourite(ref, item);
            ref.invalidate(provider);
          },
        ),
      );

  Widget? _generatedCover(LibraryItem playlist) {
    final songs = ref
        .watch(todaysPlaylistsProvider)
        .valueOrNull
        ?.firstWhereOrNull((candidate) => candidate.item.id == playlist.id)
        ?.coverSongs;
    if (songs == null || songs.isEmpty) return null;
    final images = ref.read(imageServiceProvider);
    return CoverMosaic(
      images: [for (final song in songs) images.itemImage(song)],
    );
  }

  Widget? _instantMixCover(LibraryItem item) {
    if (!isInstantMixId(item.id)) return null;
    final songs = ref
        .watch(libraryInstantMixesProvider)
        .firstWhereOrNull((mix) => mix.item.id == item.id)
        ?.songs;
    if (songs == null || songs.isEmpty) return null;
    final images = ref.read(imageServiceProvider);
    return CoverMosaic(
      images: [for (final song in songs.take(4)) images.itemImage(song)],
    );
  }

  void _refreshFavourites() => ref
    ..invalidate(favouriteAlbumsProvider)
    ..invalidate(favouritePlaylistsProvider);

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    final resumePoints = ref.watch(jumpBackInProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: TvTokens.pagePaddingV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              TvTokens.pagePaddingH - 6,
              0,
              TvTokens.pagePaddingH,
              20,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TvLibrarySelector(),
            ),
          ),
          if (isOffline)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: TvTokens.pagePaddingH,
              ),
              child: OfflineNotice(
                message:
                    "You're offline. Your library will be back "
                    'once the server is reachable.',
              ),
            )
          else ...[
            TvShelf(
              title: 'Recently added',
              items: ref.watch(recentlyAddedAlbumsProvider),
              imageFor: _image,
              subtitleFor: (item) => item.albumArtist,
              autofocusFirst: true,
              onSelect: _openAlbum,
              onLongSelect: _options(recentlyAddedAlbumsProvider),
              onRetry: () => ref.invalidate(recentlyAddedAlbumsProvider),
            ),
            if (!ref.watch(
              settingProvider(AppSetting.generatedPlaylistsDisabled),
            ))
              TvShelf(
                title: 'Made for you',
                items: ref.watch(todaysPlaylistItemsProvider),
                imageFor: _image,
                coverFor: _generatedCover,
                onSelect: _openGenerated,
                onRetry: () => ref.invalidate(todaysPlaylistsProvider),
              ),
            if (resumePoints.isNotEmpty)
              TvShelf(
                title: 'Jump back in',
                items: AsyncData([
                  for (final point in resumePoints) point.item,
                ]),
                imageFor: _image,
                subtitleFor: (item) => item.albumArtist,
                coverFor: _instantMixCover,
                playsOnSelect: (_) => true,
                onSelect: _resume,
                onLongSelect: (item) {
                  if (EphemeralPlaylistId.isEphemeral(item.id)) return;
                  _options(resumePointsProvider)(item);
                },
              ),
            if (!ref.watch(settingProvider(AppSetting.recentlyPlayedHidden)))
              TvShelf(
                title: 'Recently played',
                items: ref.watch(recentlyPlayedItemsProvider),
                imageFor: _image,
                subtitleFor: (item) => item.albumArtist,
                coverFor: _instantMixCover,
                playsOnSelect: (item) => isInstantMixId(item.id),
                onSelect: _onRecentlyPlayed,
                onLongSelect: (item) {
                  if (isInstantMixId(item.id)) return;
                  _options(recentlyPlayedAlbumsProvider)(item);
                },
                onRetry: () => ref.invalidate(recentlyPlayedAlbumsProvider),
              ),
            if (!ref.watch(settingProvider(AppSetting.favouritesHidden)))
              TvShelf(
                title: 'Favourites',
                items: ref.watch(homeFavouritesProvider),
                imageFor: _image,
                subtitleFor: (item) => item.albumArtist,
                onSelect: _onFavourite,
                onLongSelect: _options(homeFavouritesProvider),
                onRetry: _refreshFavourites,
                emptyLabel: 'Like albums and playlists to see them here',
              ),
            TvShelf(
              title: 'Playlists',
              items: ref
                  .watch(homePlaylistsProvider)
                  .whenData(
                    (list) => [
                      ?ref.watch(likedSongsPlaylistProvider),
                      ?ref.watch(onRepeatCardProvider).valueOrNull,
                      ...list,
                    ],
                  ),
              imageFor: _image,
              onSelect: _openPlaylist,
              onLongSelect: (item) {
                if (EphemeralPlaylistId.isEphemeral(item.id)) return;
                _options(homePlaylistsProvider)(item);
              },
              onRetry: () => ref.invalidate(homePlaylistsProvider),
            ),
            TvShelf(
              title: 'Frequently played',
              items: ref.watch(frequentlyPlayedAlbumsProvider),
              imageFor: _image,
              subtitleFor: (item) => item.albumArtist,
              onSelect: _openAlbum,
              onLongSelect: _options(frequentlyPlayedAlbumsProvider),
              onRetry: () => ref.invalidate(frequentlyPlayedAlbumsProvider),
            ),
          ],
        ],
      ),
    );
  }
}
