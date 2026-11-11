import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  const SearchResultsPage({required this.category, super.key});

  final ItemList category;

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  late ThemeData _theme;
  late DeviceType _device;

  Future<void> _onItemLikePressed(LibraryItem item) async {
    final updated = await toggleFavourite(ref, item);
    ref.read(searchItemsProvider(widget.category).notifier).updateItem(updated);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  Widget _error(WidgetRef ref, Object error) => SliverToBoxAdapter(
    child: ref.watch(isOfflineProvider)
        ? OfflineNotice(
            message: "You're offline, so search needs a connection.",
            onRetry: () => ref.invalidate(searchItemsProvider(widget.category)),
            showDownloadsLink: true,
          )
        : Text(error.toString()),
  );

  List<ContextMenuAction> _options(
    BuildContext context,
    WidgetRef ref,
    LibraryItem item,
  ) => contextMenuActions(
    context,
    ref,
    item,
    scope: ContextMenuScope.browse,
    onLike: _onItemLikePressed,
  );

  Widget _albumsGrid(WidgetRef ref, List<LibraryItem> items) =>
      SliverGrid.builder(
        gridDelegate: AlbumCardMetrics.gridDelegate(_device),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return AlbumView(
            album: item,
            showArtist: false,
            optionsBuilder: (context) => _options(context, ref, item),
            onTap: (item) =>
                openSearchResult(context, ref, widget.category, item),
          );
        },
      );

  Widget _artistsGrid(WidgetRef ref, List<LibraryItem> items) {
    final size = ArtistAvatarCard.avatarSize(_device);
    final imageService = ref.read(imageServiceProvider);
    return SliverGrid.builder(
      gridDelegate: ArtistAvatarCard.gridDelegate(_device),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ArtistAvatarCard(
          name: item.name,
          size: size,
          image: imageService.itemImage(item),
          optionsBuilder: (context) => _options(context, ref, item),
          onTap: () => openSearchResult(context, ref, ItemList.artists, item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchProvider)?.trim() ?? '';

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
                  previousPageTitle: 'Browse',
                  onPressed: () => context.pop(),
                ),
                SizedBox(width: _device.isMobile ? 12 : 20),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: searchCategoryLabel(widget.category),
                      children: [
                        if (query.isNotEmpty)
                          TextSpan(
                            text: '  “$query”',
                            style: TextStyle(
                              fontSize: _device.isMobile ? 14 : 18,
                              fontWeight: FontWeight.w400,
                              color: _theme.colorScheme.onPrimary.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
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
        contentPadding: EdgeInsets.only(
          left: _device.isMobile ? 16 : 30,
          right: _device.isMobile ? 16 : 30,
          bottom: 30,
        ),
        slivers: [
          Consumer(
            builder: (context, ref, child) {
              final provider = ref.watch(
                searchItemsProvider(widget.category),
              );
              return provider.when(
                data: (list) => switch (widget.category) {
                  ItemList.songs => const SearchSongsSliver(),
                  ItemList.artists => _artistsGrid(ref, list.items),
                  _ => _albumsGrid(ref, list.items),
                },
                error: (error, stackTrace) => _error(ref, error),
                loading: () => switch (widget.category) {
                  ItemList.songs => SliverToBoxAdapter(
                    child: SongRowsShimmer(device: _device, count: 8),
                  ),
                  ItemList.artists => ArtistCardsGridShimmer(device: _device),
                  _ => AlbumCardsGridShimmer(device: _device),
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
