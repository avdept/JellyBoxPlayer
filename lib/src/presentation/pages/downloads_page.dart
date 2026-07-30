import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/dto/dto.dart';
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

  void _onAlbumTap(BuildContext context, ItemDTO album) => context.pushNamed(
    Routes.album.name,
    extra: {'album': album},
  );

  Future<void> _onPlayPressed(
    BuildContext context,
    WidgetRef ref,
    ItemDTO album,
  ) async {
    try {
      final result = await ref
          .read(setPlaybackProvider.notifier)
          .playAlbum(album);
      if (result == SetPlaybackResult.empty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nothing to play in "${album.name}"')),
        );
      }
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start playing "${album.name}"')),
        );
      }
    }
  }

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
                  return Text(
                    Intl.plural(
                      albumCount,
                      one: '$albumCount album',
                      other: '$albumCount albums',
                    ),
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
            return ref
                .watch(downloadedAlbumsProvider)
                .when(
                  data: (albums) {
                    if (albums.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Text('No downloaded albums yet'),
                        ),
                      );
                    }

                    return SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: device.isTablet ? 360 : 200,
                        mainAxisSpacing: device.isMobile ? 15 : 24,
                        crossAxisSpacing: device.isMobile
                            ? 8
                            : (device.isTablet ? 56 : 28),
                        childAspectRatio: device.isTablet
                            ? 360 / 413
                            : 175 / 215.7,
                      ),
                      itemBuilder: (context, index) => DownloadedAlbumView(
                        album: albums[index],
                        onTap: (album) => _onAlbumTap(context, album),
                        onPlayPressed: (album) =>
                            _onPlayPressed(context, ref, album),
                        onDelete: (album) => ref
                            .read(downloadManagerProvider.notifier)
                            .deleteAlbum(album.id),
                      ),
                      itemCount: albums.length,
                    );
                  },
                  error: (error, stackTrace) {
                    return SliverToBoxAdapter(
                      child: Center(child: Text('Error: $error')),
                    );
                  },
                  loading: () {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                );
          },
        ),
      ],
    );
  }
}
