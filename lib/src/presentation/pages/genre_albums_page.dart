import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class GenreAlbumsPage extends ConsumerStatefulWidget {
  const GenreAlbumsPage({required this.genre, super.key});

  final LibraryItem genre;

  @override
  ConsumerState<GenreAlbumsPage> createState() => _GenreAlbumsPageState();
}

class _GenreAlbumsPageState extends ConsumerState<GenreAlbumsPage> {
  late ThemeData _theme;
  late DeviceType _device;

  void _onAlbumTap(LibraryItem album) {
    ref.read(currentAlbumProvider.notifier).setAlbum(album);
    context.pushNamed(
      Routes.album.name,
      extra: {'album': album},
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollablePageScaffold(
        useGradientBackground: true,
        navigationBar: PreferredSize(
          preferredSize: Size.fromHeight(_device.isMobile ? 60 : 100),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _device.isMobile ? 16 : 30,
            ),
            child: Row(
              children: [
                CupertinoNavigationBarBackButton(
                  color: _theme.colorScheme.onPrimary,
                  previousPageTitle: 'Genres',
                  onPressed: () => context.pop(),
                ),
                SizedBox(width: _device.isMobile ? 12 : 20),
                Expanded(
                  child: Text(
                    widget.genre.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _device.isMobile ? 18 : 24,
                      fontWeight: FontWeight.w600,
                      color: _theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        loadMoreData: () =>
            ref.read(genreAlbumsProvider(widget.genre.id).notifier).loadMore(),
        contentPadding: EdgeInsets.only(
          left: _device.isMobile ? 16 : 30,
          right: _device.isMobile ? 16 : 30,
          bottom: 30,
        ),
        slivers: [
          Consumer(
            builder: (context, ref, child) {
              final provider = ref.watch(genreAlbumsProvider(widget.genre.id));
              return provider.when(
                data: (list) => SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: _device.isTablet ? 360 : 200,
                    mainAxisSpacing: _device.isMobile ? 15 : 24,
                    crossAxisSpacing: _device.isMobile
                        ? 8
                        : (_device.isTablet ? 56 : 28),
                    childAspectRatio: _device.isTablet
                        ? 360 / 413
                        : 175 / 215.7,
                  ),
                  itemBuilder: (context, index) {
                    final item = list.items[index];
                    return AlbumView(
                      album: item,
                      onTap: _onAlbumTap,
                    );
                  },
                  itemCount: list.items.length,
                ),
                error: (error, stackTrace) => SliverToBoxAdapter(
                  child: ref.watch(isOfflineProvider)
                      ? OfflineNotice(
                          message:
                              "You're offline. This genre needs a connection.",
                          onRetry: () => ref.invalidate(
                            genreAlbumsProvider(widget.genre.id),
                          ),
                          showDownloadsLink: true,
                        )
                      : Text(error.toString()),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
