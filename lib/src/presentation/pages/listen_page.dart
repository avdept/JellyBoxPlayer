import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/dto/wrappers/wrappers_dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/album_provider.dart';
import 'package:jplayer/src/domain/providers/artist_provider.dart';
import 'package:jplayer/src/domain/providers/current_album_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ListenPage extends ConsumerStatefulWidget {
  const ListenPage({super.key});

  @override
  ConsumerState<ListenPage> createState() => _ListenPageState();
}

class _ListenPageState extends ConsumerState<ListenPage> {
  late final ValueNotifier<ListenView> _currentView;
  late final Map<EntityFilter, bool> _availableFilters;
  late final ValueNotifier<Filter> _appliedFilter;
  final _filterOpened = ValueNotifier<bool>(false);

  AlbumsWrapper albumsWrapper = const AlbumsWrapper(items: [], totalRecordCount: 0);

  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;

  Map<ListenView, String> get _viewLabels => {
        ListenView.albums: 'Albums',
        ListenView.artists: 'Artists',
      };

  Map<EntityFilter, String> get _filtersLabels => {
        EntityFilter.dateCreated: 'Date Added',
        EntityFilter.albumArtist: 'Album Artist',
        EntityFilter.sortName: 'Name',
        EntityFilter.random: 'Random',
      };

  Map<EntityFilter, bool> get _defaultSorting => {
        EntityFilter.dateCreated: true,
        EntityFilter.sortName: false,
      };

  void _onAlbumTap(ItemDTO album) {
    final location = GoRouterState.of(context).fullPath;
    ref.read(currentAlbumProvider.notifier).setAlbum(album);
    context.go('$location${Routes.album}', extra: {'album': album});
  }

  void _onArtistTap(ItemDTO artist) {
    final location = GoRouterState.of(context).fullPath;
    context.go('$location${Routes.artist}', extra: {'artist': artist});
  }

  @override
  void initState() {
    super.initState();
    _currentView = ValueNotifier(ListenView.values.first);
    _availableFilters = {
      for (final value in EntityFilter.values) value: false,
    };
    _appliedFilter = ValueNotifier(Filter(orderBy: EntityFilter.values.first));
    ref.read(albumsProvider.notifier).loadMore();
    ref.read(artistsProvider.notifier).loadMore();
  }

  Future<void> loadMore() async {
    switch (_currentView.value) {
      case ListenView.albums:
        await ref.read(albumsProvider.notifier).loadMore();
      case ListenView.artists:
        await ref.read(artistsProvider.notifier).loadMore();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _screenSize = MediaQuery.sizeOf(context);

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isTablet = deviceType == DeviceScreenType.tablet;
  }

  Widget get _albumsView => Consumer(
        builder: (context, ref, child) {
          final albumsState = ref.watch(albumsProvider);
          return albumsState.when(
            data: (AlbumsState state) {
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _isTablet ? 360 : 200,
                  mainAxisSpacing: _isMobile ? 15 : 24,
                  crossAxisSpacing: _isMobile ? 8 : (_isTablet ? 56 : 28),
                  childAspectRatio: _isTablet ? 360 / 413 : 175 / 215.7,
                ),
                itemBuilder: (context, index) => AlbumView(
                  album: state.items[index],
                  onTap: () => _onAlbumTap(state.items[index]),
                ),
                itemCount: state.items.length,
              );
            },
            error: (error, stackTrace) => SliverToBoxAdapter(child: Text(error.toString())),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          );
        },
      );

  Widget get _artistsView => Consumer(
        builder: (context, ref, child) {
          final artistsState = ref.watch(artistsProvider);

          return artistsState.when(
            data: (ArtistState state) {
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _isTablet ? 360 : 200,
                  mainAxisSpacing: _isMobile ? 15 : 24,
                  crossAxisSpacing: _isMobile ? 8 : (_isTablet ? 56 : 28),
                  childAspectRatio: _isTablet ? 360 / 413 : 175 / 215.7,
                ),
                itemBuilder: (context, index) => AlbumView(
                  album: state.items[index],
                  onTap: () => _onArtistTap(state.items[index]),
                ),
                itemCount: state.items.length,
              );
            },
            error: (error, stackTrace) => SliverToBoxAdapter(child: Text(error.toString())),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(_isMobile ? 60 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pageViewToggle(),
              _filterButton(),
            ],
          ),
        ),
      ),
      loadMoreData: loadMore,
      contentPadding: EdgeInsets.only(
        left: _isMobile ? 16 : 30,
        right: _isMobile ? 16 : 30,
        bottom: 30,
      ),
      slivers: [
        ValueListenableBuilder(
          valueListenable: _currentView,
          builder: (context, value, child) {
            switch (value) {
              case ListenView.albums:
                return _albumsView;
              case ListenView.artists:
                return _artistsView;
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _currentView.dispose();
    _appliedFilter.dispose();
    _filterOpened.dispose();
    super.dispose();
  }

  Widget _pageViewToggle() => ChipTheme(
        data: ChipTheme.of(context).copyWith(
          labelStyle: TextStyle(fontSize: _isMobile ? 14 : 16),
        ),
        child: Wrap(
          spacing: 12,
          children: [
            for (final value in ListenView.values)
              ValueListenableBuilder(
                valueListenable: _currentView,
                builder: (context, currentView, child) => ActionChip(
                    label: Text(_viewLabels[value] ?? '???'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: (value == currentView) ? _theme.chipTheme.selectedColor : _theme.chipTheme.backgroundColor,
                    onPressed: () {
                      _currentView.value = value;
                      _applyProviderFilter(_currentView.value == ListenView.albums ? EntityFilter.dateCreated : EntityFilter.sortName);
                      _appliedFilter.value =
                          Filter(orderBy: _currentView.value == ListenView.albums ? EntityFilter.dateCreated : EntityFilter.sortName, desc: true);
                    }),
              ),
          ],
        ),
      );

  String _filterLabel(EntityFilter filter) {
    return _filtersLabels[filter] ?? '???';
  }

  List<EntityFilter> getFilterItems() {
    switch (_currentView.value) {
      case ListenView.albums:
        return EntityFilter.values.toList();
      case ListenView.artists:
        return [EntityFilter.sortName, EntityFilter.dateCreated];
    }
  }

  void _applyProviderFilter(EntityFilter? value) {
    final filter = ref.read(filterProvider);
    if (filter.orderBy == value) {
      final desc = !filter.desc;
      ref.read(filterProvider.notifier).filter(value!, desc);
    } else {
      ref.read(filterProvider.notifier).filter(value!, _defaultSorting[value] ?? false);
    }
  }

  Widget _filterButton() => DropdownButtonHideUnderline(
        child: ValueListenableBuilder(
          valueListenable: _currentView,
          builder: (context, view, widget) {
            return Consumer(
              builder: (context, ref, child) {
                final filter = ref.watch(filterProvider);
                return DropdownButton2<EntityFilter>(
                  customButton: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ValueListenableBuilder(
                      valueListenable: _filterOpened,
                      builder: (context, isOpened, child) => Icon(
                        JPlayer.sliders,
                        color: isOpened ? _theme.colorScheme.primary : _theme.iconTheme.color,
                      ),
                    ),
                  ),
                  buttonStyleData: const ButtonStyleData(
                    overlayColor: MaterialStatePropertyAll(Colors.transparent),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    width: 150,
                    padding: const EdgeInsets.all(8),
                    offset: const Offset(0, -8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  items: [
                    for (final value in getFilterItems())
                      DropdownMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _filterLabel(value),
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.2,
                                  color: (filter.orderBy == value) ? _theme.colorScheme.primary : _theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              filter.desc ? Icons.arrow_upward : Icons.arrow_downward,
                              color: (filter.orderBy == value) ? _theme.colorScheme.primary : _theme.colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                  ],
                  value: filter.orderBy,
                  onChanged: _applyProviderFilter,
                  onMenuStateChange: (value) => _filterOpened.value = value,
                );
              },
            );
          },
        ),
      );
}
