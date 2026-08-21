import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/scrollable_page_scaffold.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const _sortOptions = <EntityFilter, String>{
  EntityFilter.sortName: 'Name',
  EntityFilter.dateCreated: 'Date Added',
  EntityFilter.albumArtist: 'Album Artist',
  EntityFilter.random: 'Random',
};

class FavouriteSongsPage extends ConsumerStatefulWidget {
  const FavouriteSongsPage({super.key});

  @override
  ConsumerState<FavouriteSongsPage> createState() => _FavouriteSongsPageState();
}

class _FavouriteSongsPageState extends ConsumerState<FavouriteSongsPage> {
  var _filter = const Filter(orderBy: EntityFilter.sortName);

  late ThemeData _theme;
  late DeviceType _device;

  double get _horizontalPadding => _device.isMobile ? 16 : 30;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  void _applySort(EntityFilter field) {
    setState(() {
      _filter = _filter.orderBy == field
          ? _filter.copyWith(desc: !_filter.desc)
          : Filter(orderBy: field, desc: field == EntityFilter.dateCreated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    final songs = ref.watch(favouriteSongsListProvider(_filter));

    return ScrollablePageScaffold(
      useGradientBackground: true,
      loadMoreData: () =>
          ref.read(favouriteSongsListProvider(_filter).notifier).loadMore(),
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(_device.isMobile ? 60 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Row(
            children: [
              CupertinoNavigationBarBackButton(
                color: _theme.colorScheme.onPrimary,
                onPressed: () => context.pop(),
              ),
              SizedBox(width: _device.isMobile ? 12 : 20),
              Expanded(
                child: Text(
                  'Favourite songs',
                  style: TextStyle(
                    fontSize: _device.isMobile ? 20 : 26,
                    fontWeight: FontWeight.w600,
                    color: _theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              _sortButton(),
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
                    "You're offline, so your favourites need a connection.",
                onRetry: () =>
                    ref.invalidate(favouriteSongsListProvider(_filter)),
                showDownloadsLink: true,
              ),
            ),
          )
        else
          ...songs.when(
            data: (page) => [
              SongListSliver(
                songs: page.items,
                edgePadding: _horizontalPadding,
                onItemUpdated: ref
                    .read(favouriteSongsListProvider(_filter).notifier)
                    .updateItem,
              ),
            ],
            error: (error, stackTrace) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(error.toString())),
                ),
              ),
            ],
            loading: () => [
              SliverToBoxAdapter(
                child: SongRowsShimmer(
                  device: _device,
                  count: 8,
                  edgePadding: _horizontalPadding,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _sortButton() => PopupMenuButton<EntityFilter>(
    icon: const Icon(Icons.sort),
    tooltip: 'Sort',
    onSelected: _applySort,
    itemBuilder: (context) => [
      for (final entry in _sortOptions.entries)
        PopupMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Expanded(child: Text(entry.value)),
              if (_filter.orderBy == entry.key)
                Icon(
                  _filter.desc ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 18,
                ),
            ],
          ),
        ),
    ],
  );
}
