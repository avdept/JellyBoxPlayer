import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  const SearchResultsPage({required this.category, super.key});

  final ItemList category;

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  late ThemeData _theme;
  late DeviceType _device;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
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
                data: (list) => widget.category == ItemList.songs
                    ? const SearchSongsSliver()
                    : SliverGrid.builder(
                        gridDelegate: AlbumCardMetrics.gridDelegate(_device),
                        itemBuilder: (context, index) {
                          final item = list.items[index];
                          return AlbumView(
                            album: item,
                            showArtist: widget.category == ItemList.artists,
                            onTap: (item) => openSearchResult(
                              context,
                              ref,
                              widget.category,
                              item,
                            ),
                          );
                        },
                        itemCount: list.items.length,
                      ),
                error: (error, stackTrace) => SliverToBoxAdapter(
                  child: ref.watch(isOfflineProvider)
                      ? OfflineNotice(
                          message:
                              "You're offline, so search needs a "
                              'connection.',
                          onRetry: () => ref.invalidate(
                            searchItemsProvider(widget.category),
                          ),
                          showDownloadsLink: true,
                        )
                      : Text(error.toString()),
                ),
                loading: () => widget.category == ItemList.songs
                    ? SliverToBoxAdapter(
                        child: SongRowsShimmer(device: _device, count: 8),
                      )
                    : AlbumCardsGridShimmer(device: _device),
              );
            },
          ),
        ],
      ),
    );
  }
}
