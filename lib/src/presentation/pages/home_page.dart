import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/dev_tools_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _iconRowHeight = 48.0;

  late DeviceType _device;

  double get _horizontalPadding => _device.isMobile ? 16 : 30;

  double get _navigationBarHeight => _device.isMobile ? _iconRowHeight : 100;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  void _onAlbumTap(LibraryItem album) {
    ref.read(currentAlbumProvider.notifier).setAlbum(album);
    context.pushNamed(
      branchAwareName(context, Routes.album),
      extra: {'album': album},
    );
  }

  void _onPlaylistTap(LibraryItem playlist) {
    if (playlist.id == likedSongsPlaylistId) {
      context.pushNamed(branchAwareName(context, Routes.favouriteSongs));
      return;
    }
    ref.read(currentPlaylistProvider.notifier).setPlaylist(playlist);
    context.pushNamed(
      branchAwareName(context, Routes.playlist),
      extra: {'playlist': playlist},
    );
  }

  Future<void> _onPlayAlbum(LibraryItem album) => _play(
    album,
    () => ref.read(setPlaybackProvider.notifier).playAlbum(album),
  );

  Future<void> _onPlayPlaylist(LibraryItem playlist) => _play(
    playlist,
    () => playlist.id == likedSongsPlaylistId
        ? ref.read(setPlaybackProvider.notifier).playFavouriteSongs(playlist)
        : ref.read(setPlaybackProvider.notifier).playPlaylist(playlist),
  );

  Future<void> _play(
    LibraryItem item,
    Future<SetPlaybackResult> Function() action,
  ) async {
    final result = await action();
    if (result == SetPlaybackResult.empty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nothing to play in "${item.name}"')),
      );
    }
  }

  Widget? _playlistCover(LibraryItem playlist) {
    if (playlist.id != likedSongsPlaylistId) return null;
    final covers = ref.watch(likedSongsCoversProvider);
    if (covers.isEmpty) return null;

    final imageService = ref.read(imageServiceProvider);
    return CoverMosaic(
      images: [for (final song in covers) imageService.itemImage(song)],
    );
  }

  void _onGeneratedPlaylistTap(LibraryItem playlist) => context.pushNamed(
    Routes.homeGeneratedPlaylist.name,
    extra: {'playlist': playlist},
  );

  Future<void> _onPlayGeneratedPlaylist(LibraryItem playlist) => _play(
    playlist,
    () =>
        ref.read(setPlaybackProvider.notifier).playGeneratedPlaylist(playlist),
  );

  Widget? _generatedPlaylistCover(LibraryItem playlist) {
    final playlists = ref.watch(todaysPlaylistsProvider).valueOrNull;
    final songs = playlists
        ?.firstWhereOrNull((candidate) => candidate.item.id == playlist.id)
        ?.coverSongs;
    if (songs == null || songs.isEmpty) return null;

    final imageService = ref.read(imageServiceProvider);
    return CoverMosaic(
      images: [for (final song in songs) imageService.itemImage(song)],
    );
  }

  Widget _regenerateButton() => IconButton(
    onPressed: () =>
        unawaited(ref.read(todaysPlaylistsProvider.notifier).regenerate()),
    icon: const Icon(Icons.refresh),
    iconSize: 20,
    tooltip: 'Rebuild mixes (debug)',
    color: Theme.of(context).colorScheme.onPrimary,
  );

  void _onFavouritesTap() =>
      context.pushNamed(branchAwareName(context, Routes.favourites));

  void _refresh() {
    ref
      ..invalidate(favouriteAlbumsProvider)
      ..invalidate(recentlyPlayedAlbumsProvider)
      ..invalidate(frequentlyPlayedAlbumsProvider)
      ..invalidate(recentlyAddedAlbumsProvider)
      ..invalidate(recentlyUpdatedPlaylistsProvider)
      ..invalidate(todaysPlaylistsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);

    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(_navigationBarHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Row(
            children: [
              LibrarySelectorButton(
                size: _device.isMobile ? 32 : 40,
                showName: true,
              ),
              const Spacer(),
              UpdatifyBell(isDesktop: _device.isDesktop),
            ],
          ),
        ),
      ),
      contentPadding: const EdgeInsets.only(bottom: 30),
      slivers: [
        if (isOffline)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: OfflineNotice(
                message:
                    "You're offline. Your library will be back "
                    'once the server is reachable.',
                onRetry: _refresh,
                showDownloadsLink: true,
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: ItemCarousel(
              title: 'Recently played',
              items: ref.watch(recentlyPlayedAlbumsProvider),
              device: _device,
              horizontalPadding: _horizontalPadding,
              onItemTap: _onAlbumTap,
              onPlayPressed: _onPlayAlbum,
              onRetry: () => ref.invalidate(recentlyPlayedAlbumsProvider),
            ),
          ),
          if (!ref.watch(settingProvider(AppSetting.generatedPlaylistsDisabled)))
            SliverToBoxAdapter(
              child: ItemCarousel(
                title: 'Made for you',
                items: ref.watch(todaysPlaylistItemsProvider),
                device: _device,
                horizontalPadding: _horizontalPadding,
                onItemTap: _onGeneratedPlaylistTap,
                onPlayPressed: _onPlayGeneratedPlaylist,
                coverBuilder: _generatedPlaylistCover,
                onRetry: () => ref.invalidate(todaysPlaylistsProvider),
                trailing: ref.watch(devToolsEnabledProvider)
                    ? _regenerateButton()
                    : null,
              ),
            ),
          SliverToBoxAdapter(
            child: ItemCarousel(
              title: 'Recently added',
              items: ref.watch(recentlyAddedAlbumsProvider),
              device: _device,
              horizontalPadding: _horizontalPadding,
              onItemTap: _onAlbumTap,
              onPlayPressed: _onPlayAlbum,
              onRetry: () => ref.invalidate(recentlyAddedAlbumsProvider),
            ),
          ),
          SliverToBoxAdapter(
            child: ItemCarousel(
              title: 'Favourites',
              items: ref.watch(favouriteAlbumsProvider),
              device: _device,
              horizontalPadding: _horizontalPadding,
              onItemTap: _onAlbumTap,
              onPlayPressed: _onPlayAlbum,
              onTitleTap: _onFavouritesTap,
              onRetry: () => ref.invalidate(favouriteAlbumsProvider),
            ),
          ),
          SliverToBoxAdapter(
            child: ItemCarousel(
              title: 'Playlists',
              items: ref
                  .watch(recentlyUpdatedPlaylistsProvider)
                  .whenData((list) => [likedSongsPlaylist, ...list]),
              device: _device,
              horizontalPadding: _horizontalPadding,
              onItemTap: _onPlaylistTap,
              onPlayPressed: _onPlayPlaylist,
              coverBuilder: _playlistCover,
              onRetry: () => ref.invalidate(recentlyUpdatedPlaylistsProvider),
            ),
          ),
          SliverToBoxAdapter(
            child: ItemCarousel(
              title: 'Frequently played',
              items: ref.watch(frequentlyPlayedAlbumsProvider),
              device: _device,
              horizontalPadding: _horizontalPadding,
              onItemTap: _onAlbumTap,
              onPlayPressed: _onPlayAlbum,
              onRetry: () => ref.invalidate(frequentlyPlayedAlbumsProvider),
            ),
          ),
        ],
      ],
    );
  }
}
