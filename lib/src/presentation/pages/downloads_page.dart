import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

@visibleForTesting
class DownloadsPageKeys {
  @visibleForTesting
  const DownloadsPageKeys({
    required this.counterText,
  });

  final Key counterText;
}

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({
    @visibleForTesting this.testKeys,
    super.key,
  });

  final DownloadsPageKeys? testKeys;

  SliverGridDelegate _gridDelegate(DeviceType device) =>
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: device.isTablet ? 360 : 200,
        mainAxisSpacing: device.isMobile ? 15 : 24,
        crossAxisSpacing: device.isMobile ? 8 : (device.isTablet ? 56 : 28),
        childAspectRatio: device.isTablet ? 360 / 413 : 175 / 215.7,
      );

  void _onAlbumTap(BuildContext context, DownloadedAlbum album) =>
      context.pushNamed(
        Routes.album.name,
        extra: {'album': album.item},
      );

  void _onPlaylistTap(BuildContext context, DownloadedPlaylist playlist) =>
      context.pushNamed(
        Routes.playlist.name,
        extra: {'playlist': playlist.item},
      );

  Future<void> _play(
    BuildContext context,
    LibraryItem item,
    Future<SetPlaybackResult> Function() start,
  ) async {
    try {
      final result = await start();
      if (result == SetPlaybackResult.empty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nothing to play in "${item.name}"')),
        );
      }
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start playing "${item.name}"')),
        );
      }
    }
  }

  String _counterLabel(int albumCount, int playlistCount) {
    final albums = Intl.plural(
      albumCount,
      one: '$albumCount album',
      other: '$albumCount albums',
    );
    if (playlistCount == 0) return albums;
    final playlists = Intl.plural(
      playlistCount,
      one: '$playlistCount playlist',
      other: '$playlistCount playlists',
    );
    return '$albums • $playlists';
  }

  Widget _sectionHeader(DeviceType device, String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: device.isMobile ? 16 : 22,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));

    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(device.isMobile ? 60 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: device.isMobile ? 16 : 30),
          child: Row(
            children: [
              Text(
                'Downloads',
                style: TextStyle(
                  fontSize: device.isMobile ? 24 : 36,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              SizedBox(width: device.isMobile ? 12 : 24),
              Consumer(
                builder: (context, ref, child) {
                  final albumCount =
                      ref.watch(downloadedAlbumsProvider).valueOrNull?.length ??
                      0;
                  final playlistCount =
                      ref
                          .watch(downloadedPlaylistsProvider)
                          .valueOrNull
                          ?.length ??
                      0;
                  return Text(
                    _counterLabel(albumCount, playlistCount),
                    key: testKeys?.counterText,
                    style: TextStyle(
                      fontSize: device.isMobile ? 12 : 16,
                      height: 1.2,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: device.isMobile ? 16 : 30,
        right: device.isMobile ? 16 : 30,
        bottom: 30,
      ),
      slivers: [
        Consumer(
          builder: (context, ref, child) {
            final albums = ref.watch(downloadedAlbumsProvider);
            final playlists = ref.watch(downloadedPlaylistsProvider);

            if (albums.isLoading || playlists.isLoading) {
              return AlbumCardsGridShimmer(
                device: device,
                gridDelegate: _gridDelegate(device),
              );
            }

            final error = albums.error ?? playlists.error;
            if (error != null) {
              return SliverToBoxAdapter(
                child: Center(child: Text('Error: $error')),
              );
            }

            final albumItems = albums.valueOrNull ?? const [];
            final playlistItems = playlists.valueOrNull ?? const [];

            if (albumItems.isEmpty && playlistItems.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(child: Text('No downloads yet')),
              );
            }

            return SliverMainAxisGroup(
              slivers: [
                if (playlistItems.isNotEmpty) ...[
                  _sectionHeader(device, 'Playlists'),
                  SliverGrid.builder(
                    gridDelegate: _gridDelegate(device),
                    itemBuilder: (context, index) => DownloadedPlaylistView(
                      playlist: playlistItems[index],
                      onTap: (playlist) => _onPlaylistTap(context, playlist),
                      onPlayPressed: (playlist) => _play(
                        context,
                        playlist.item,
                        () => ref
                            .read(setPlaybackProvider.notifier)
                            .playPlaylist(playlist.item),
                      ),
                      onDelete: (playlist) => ref
                          .read(downloadManagerProvider.notifier)
                          .deletePlaylist(playlist.item.id),
                    ),
                    itemCount: playlistItems.length,
                  ),
                ],
                if (albumItems.isNotEmpty) ...[
                  if (playlistItems.isNotEmpty)
                    _sectionHeader(device, 'Albums'),
                  SliverGrid.builder(
                    gridDelegate: _gridDelegate(device),
                    itemBuilder: (context, index) => DownloadedAlbumView(
                      album: albumItems[index],
                      onTap: (album) => _onAlbumTap(context, album),
                      onPlayPressed: (album) => _play(
                        context,
                        album.item,
                        () => ref
                            .read(setPlaybackProvider.notifier)
                            .playAlbum(album.item),
                      ),
                      onDelete: (album) => ref
                          .read(downloadManagerProvider.notifier)
                          .deleteAlbum(album.item.id),
                    ),
                    itemCount: albumItems.length,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
