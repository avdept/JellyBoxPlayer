import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/scrollable_page_scaffold.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class FavouritesPage extends ConsumerStatefulWidget {
  const FavouritesPage({super.key});

  @override
  ConsumerState<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends ConsumerState<FavouritesPage> {
  late ThemeData _theme;
  late DeviceType _device;

  double get _horizontalPadding => _device.isMobile ? 16 : 30;

  double get _navigationBarHeight => _device.isMobile ? 56 : 64;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  void _refresh() {
    ref
      ..invalidate(favouriteAlbumsProvider)
      ..invalidate(favouriteArtistsProvider)
      ..invalidate(favouriteSongsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    final albums = ref.watch(favouriteAlbumsProvider).valueOrNull ?? const [];
    final artists = ref.watch(favouriteArtistsProvider).valueOrNull ?? const [];
    final songsPage =
        ref.watch(favouriteSongsProvider).valueOrNull ?? const LibraryPage();
    final songs = songsPage.items;
    final hasMoreSongs = songsPage.totalRecordCount > songs.length;

    final isLoading =
        ref.watch(favouriteAlbumsProvider).isLoading ||
        ref.watch(favouriteArtistsProvider).isLoading ||
        ref.watch(favouriteSongsProvider).isLoading;

    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(_navigationBarHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Row(
            children: [
              const BackButton(),
              const SizedBox(width: 4),
              Text(
                'Favourites',
                style: TextStyle(
                  fontSize: _device.isMobile ? 22 : 26,
                  fontWeight: FontWeight.w600,
                  color: _theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: _horizontalPadding,
        right: _horizontalPadding,
        bottom: 30,
      ),
      slivers: [
        if (isOffline)
          SliverToBoxAdapter(
            child: OfflineNotice(
              message:
                  "You're offline. Your favourites will be back "
                  'once the server is reachable.',
              onRetry: _refresh,
              showDownloadsLink: true,
            ),
          )
        else if (isLoading &&
            albums.isEmpty &&
            artists.isEmpty &&
            songs.isEmpty)
          SliverToBoxAdapter(
            child: SectionsShimmer(device: _device, cardRows: 2),
          )
        else if (albums.isEmpty && artists.isEmpty && songs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "You haven't favourited anything yet.",
                  style: TextStyle(
                    fontSize: _device.isMobile ? 14 : 16,
                    color: _theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else ...[
          ..._cardsSection(ItemList.albums, albums),
          ..._cardsSection(ItemList.artists, artists),
          if (songs.isNotEmpty) ...[
            _sectionHeader('Songs'),
            SongListSliver(
              songs: songs,
              onItemUpdated: (_) => ref.invalidate(favouriteSongsProvider),
            ),
            if (hasMoreSongs)
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.pushNamed(
                      branchAwareName(context, Routes.favouriteSongs),
                    ),
                    child: Text(
                      'Show all ${songsPage.totalRecordCount} songs',
                    ),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  List<Widget> _cardsSection(ItemList category, List<LibraryItem> items) {
    if (items.isEmpty) return const [];

    final cardWidth = AlbumCardMetrics.width(_device);
    final spacing = AlbumCardMetrics.crossAxisSpacing(_device);

    return [
      _sectionHeader(searchCategoryLabel(category)),
      SliverToBoxAdapter(
        child: SizedBox(
          height: AlbumCardMetrics.height(
            cardWidth,
            isTablet: _device.isTablet,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) => SizedBox(width: spacing),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: AlbumView(
                album: items[index],
                showArtist: category == ItemList.artists,
                onTap: (item) => openSearchResult(context, ref, category, item),
              ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: _device.isMobile ? 16 : 24),
      ),
    ];
  }

  Widget _sectionHeader(String label) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    ),
  );
}
