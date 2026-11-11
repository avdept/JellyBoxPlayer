import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';
import 'package:jplayer/src/presentation/widgets/artist_avatar_card.dart';
import 'package:jplayer/src/presentation/widgets/clickable_widget.dart';
import 'package:jplayer/src/presentation/widgets/cover_mosaic.dart';
import 'package:jplayer/src/presentation/widgets/horizontal_scroll_region.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/search_songs_sliver.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/presentation/widgets/similar_artists_row.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

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
    final soundMatches = ref.watch(soundSearchProvider);
    final soundItems = soundMatches.valueOrNull ?? const <LibraryItem>[];
    final localArtists =
        sections[ItemList.artists]?.valueOrNull?.items ?? const <LibraryItem>[];
    final catalogArtists = ref
        .watch(catalogArtistSearchProvider)
        .whenData((found) => catalogArtistsOutsideLibrary(found, localArtists));
    final hasItems =
        soundItems.isNotEmpty ||
        (catalogArtists.valueOrNull?.isNotEmpty ?? false) ||
        sections.values.any(
          (section) => section.valueOrNull?.items.isNotEmpty ?? false,
        );

    if (!hasItems) {
      final isSearching =
          isPending ||
          soundMatches.isLoading ||
          catalogArtists.isLoading ||
          sections.values.any((section) => section.isLoading);
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
        ..._soundMixSection(context, ref, device, soundItems),
        for (final entry in sections.entries) ...[
          ..._section(
            context: context,
            ref: ref,
            device: device,
            category: entry.key,
            items: entry.value.valueOrNull?.items ?? const [],
          ),
          if (entry.key == ItemList.artists)
            _catalogArtistsSection(ref, device, catalogArtists),
        ],
      ],
    );
  }

  Widget _catalogArtistsSection(
    WidgetRef ref,
    DeviceType device,
    AsyncValue<List<SimilarArtist>> artists,
  ) {
    if (ref.watch(catalogSourcesProvider).isEmpty) {
      return const SliverToBoxAdapter();
    }
    return SliverToBoxAdapter(
      child: SimilarArtistsRow(
        artists: artists,
        device: device,
        title: "Artists you don't track",
        titleFontSize: 18,
        showPlaceholder: true,
      ),
    );
  }

  List<Widget> _soundMixSection(
    BuildContext context,
    WidgetRef ref,
    DeviceType device,
    List<LibraryItem> songs,
  ) {
    if (songs.isEmpty) return const [];

    final query = ref.watch(searchProvider)?.trim() ?? '';
    final seed = soundMixSeed(query);
    final mixItem = seed.copyWith(name: '${seed.name} Mix');
    final imageService = ref.read(imageServiceProvider);
    final cardWidth = AlbumCardMetrics.width(device);

    InstantMix? register() => ref.read(soundSearchProvider.notifier).mix();

    return [
      _header(
        context,
        ItemList.songs,
        label: soundSearchLabel,
        showChevron: false,
      ),
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: cardWidth,
            height: AlbumCardMetrics.height(cardWidth),
            child: AlbumView(
              album: mixItem,
              showArtist: false,
              showDownloadBadge: false,
              subtitle: '${songs.length} songs',
              coverOverride: CoverMosaic(
                images: [
                  for (final song in songs.take(4))
                    imageService.itemImage(song),
                ],
              ),
              onTap: (_) {
                final mix = register();
                if (mix == null) return;
                context.pushNamed(
                  branchAwareName(context, Routes.instantMix),
                  extra: {'mix': mix.item},
                );
              },
              onPlayPressed: (_) async {
                final mix = register();
                if (mix == null) return;
                await ref
                    .read(setPlaybackProvider.notifier)
                    .playInstantMix(mix);
              },
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: device.isMobile ? 16 : 24),
      ),
    ];
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
    String? label,
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
                label ?? searchCategoryLabel(category),
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
    if (category == ItemList.artists) {
      return _artistsRow(context, ref, device, items);
    }

    final cardWidth = AlbumCardMetrics.width(device);
    final spacing = AlbumCardMetrics.crossAxisSpacing(device);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: AlbumCardMetrics.height(cardWidth),
        child: HorizontalScrollRegion(
          controlsHeight: cardWidth,
          builder: (context, controller) => ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) => SizedBox(width: spacing),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: AlbumView(
                album: items[index],
                showArtist: false,
                onTap: (item) => openSearchResult(context, ref, category, item),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _artistsRow(
    BuildContext context,
    WidgetRef ref,
    DeviceType device,
    List<LibraryItem> items,
  ) {
    final size = ArtistAvatarCard.avatarSize(device);
    final spacing = AlbumCardMetrics.carouselSpacing(device);
    final imageService = ref.read(imageServiceProvider);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: ArtistAvatarCard.cardHeight(size),
        child: HorizontalScrollRegion(
          controlsHeight: size,
          builder: (context, controller) => ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) => SizedBox(width: spacing),
            itemBuilder: (context, index) {
              final item = items[index];
              return ArtistAvatarCard(
                name: item.name,
                size: size,
                image: imageService.itemImage(item),
                onTap: () =>
                    openSearchResult(context, ref, ItemList.artists, item),
              );
            },
          ),
        ),
      ),
    );
  }
}
