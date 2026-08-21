import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';
import 'package:jplayer/src/presentation/widgets/clickable_widget.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/search_songs_sliver.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class SearchResultsSliver extends ConsumerWidget {
  const SearchResultsSliver({this.isPending = false, super.key});

  final bool isPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));

    if (ref.watch(isOfflineProvider)) {
      return const SliverToBoxAdapter(
        child: OfflineNotice(
          message: "You're offline, so search needs a connection.",
          showDownloadsLink: true,
        ),
      );
    }

    final sections = {
      for (final category in searchCategories)
        category: ref.watch(searchItemsProvider(category)),
    };
    final hasItems = sections.values.any(
      (section) => section.valueOrNull?.items.isNotEmpty ?? false,
    );

    if (!hasItems) {
      final isSearching =
          isPending || sections.values.any((section) => section.isLoading);
      if (isSearching) {
        return SliverToBoxAdapter(child: SectionsShimmer(device: device));
      }

      final hasError = sections.values.any((section) => section.hasError);
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              hasError ? 'Search failed. Try again.' : 'Nothing found',
              style: TextStyle(
                fontSize: device.isMobile ? 14 : 16,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
              ),
            ),
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        for (final entry in sections.entries)
          ..._section(
            context: context,
            ref: ref,
            device: device,
            category: entry.key,
            items: entry.value.valueOrNull?.items ?? const [],
          ),
      ],
    );
  }

  List<Widget> _section({
    required BuildContext context,
    required WidgetRef ref,
    required DeviceType device,
    required ItemList category,
    required List<LibraryItem> items,
  }) {
    if (items.isEmpty) return const [];

    final isSongs = category == ItemList.songs;
    final songsLimit = searchSongsPreviewLimit(isMobile: device.isMobile);
    final hasMore = !isSongs || items.length > songsLimit;

    return [
      _header(context, category, showChevron: hasMore),
      if (isSongs)
        SearchSongsSliver(limit: songsLimit)
      else
        _cardsRow(context, ref, device, category, items),
      SliverToBoxAdapter(
        child: SizedBox(height: device.isMobile ? 16 : 24),
      ),
    ];
  }

  Widget _header(
    BuildContext context,
    ItemList category, {
    required bool showChevron,
  }) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClickableWidget(
          onPressed: showChevron
              ? () => context.pushNamed(
                  Routes.searchResults.name,
                  extra: {'category': category},
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                searchCategoryLabel(category),
                style: const TextStyle(fontSize: 18),
              ),
              if (showChevron) const Icon(Icons.chevron_right, size: 22),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _cardsRow(
    BuildContext context,
    WidgetRef ref,
    DeviceType device,
    ItemList category,
    List<LibraryItem> items,
  ) {
    final cardWidth = AlbumCardMetrics.width(device);
    final spacing = AlbumCardMetrics.crossAxisSpacing(device);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: AlbumCardMetrics.height(cardWidth, isTablet: device.isTablet),
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
    );
  }
}
