import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/albums_provider.dart';
import 'package:jplayer/src/domain/providers/artists_provider.dart';
import 'package:jplayer/src/domain/providers/current_album_provider.dart';
import 'package:jplayer/src/domain/providers/current_playlist_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:jplayer/src/domain/providers/playlists_provider.dart';
import 'package:jplayer/src/domain/providers/songs_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum _ListenPageType {
  regular,
  favorites,
}

class ListenPage extends ConsumerStatefulWidget {
  const ListenPage({super.key}) : _type = _ListenPageType.regular;

  const ListenPage.favorites({super.key}) : _type = _ListenPageType.favorites;

  final _ListenPageType _type;

  @override
  ConsumerState<ListenPage> createState() => _ListenPageState();
}

class _ListenPageState extends ConsumerState<ListenPage> {
  late final ValueNotifier<ListenView> _currentView;
  late final Map<EntityFilter, bool> _availableFilters;
  late final ValueNotifier<Filter> _appliedFilter;
  final _filterOpened = ValueNotifier<bool>(false);
  final _currentSong = ValueNotifier<MediaItem?>(null);
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late ThemeData _theme;
  late DeviceType _device;

  bool get _isFavorites => widget._type == _ListenPageType.favorites;

  Map<ListenView, String> get _viewLabels => {
        ListenView.albums: 'Albums',
        ListenView.artists: 'Artists',
        ListenView.playlists: 'Playlists',
        ListenView.songs: 'Songs',
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

  void _onPlaylistTap(ItemDTO playlist) {
    final location = GoRouterState.of(context).fullPath;
    ref.read(currentPlaylistProvider.notifier).setPlaylist(playlist);
    context.go('$location${Routes.playlist}', extra: {'playlist': playlist});
  }

  void _onCreateNewPlaylist() {
    if (_device.isDesktop) {
      showAdaptiveDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: CreatePlaylistForm(
            onCreated: () => ref.invalidate(playlistsProvider),
          ),
        ),
      );
    } else {
      PersistentBottomSheetController? controller;
      _scaffoldKey.currentState?.showBodyScrim(true, 0.66);
      controller = _scaffoldKey.currentState?.showBottomSheet(
        (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CloseButton(onPressed: controller?.close),
            CreatePlaylistForm(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              onCreated: () => ref.invalidate(playlistsProvider),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onDeletePlaylist(ItemDTO playlist) async {
    final shouldDelete = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text.rich(
          TextSpan(
            text: 'Delete ',
            children: [
              TextSpan(
                text: '"${playlist.name}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDefaultAction: true,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (shouldDelete ?? false) {
      await ref
          .read(jellyfinApiProvider)
          .deletePlaylist(playlistId: playlist.id);
      ref.invalidate(playlistsProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentView = ValueNotifier(ListenView.values.first)
      ..addListener(
        () => _appliedFilter.value = Filter(
          orderBy: _currentView.value == ListenView.albums
              ? EntityFilter.dateCreated
              : EntityFilter.sortName,
          desc: true,
        ),
      );
    _availableFilters = {
      for (final value in EntityFilter.values) value: false,
    };
    _appliedFilter = ValueNotifier(Filter(orderBy: EntityFilter.values.first))
      ..addListener(() => _applyProviderFilter(_appliedFilter.value.orderBy));
    ref.read(playerProvider).sequenceStateStream.listen((event) {
      if (event != null && mounted) {
        _currentSong.value =
            event.sequence[event.currentIndex].tag as MediaItem;
      }
    });
  }

  Future<void> loadMore() async => switch (_currentView.value) {
        ListenView.albums => ref
            .read(
              (_isFavorites ? favoriteAlbumsProvider : albumsProvider).notifier,
            )
            .loadMore(),
        ListenView.artists => ref
            .read(
              (_isFavorites ? favoriteArtistsProvider : artistsProvider)
                  .notifier,
            )
            .loadMore(),
        ListenView.playlists => ref
            .read(
              (_isFavorites ? favoritePlaylistsProvider : playlistsProvider)
                  .notifier,
            )
            .loadMore(),
        ListenView.songs => ref.read(favoriteSongsProvider.notifier).loadMore(),
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
                Expanded(child: _pageViewToggle()),
                _addButton(),
                _filterButton(),
              ],
            ),
          ),
        ),
        loadMoreData: loadMore,
        contentPadding: EdgeInsets.only(
          left: _device.isMobile ? 16 : 30,
          right: _device.isMobile ? 16 : 30,
          bottom: 30,
        ),
        slivers: [
          ValueListenableBuilder(
            valueListenable: _currentView,
            builder: (context, value, child) => Consumer(
              builder: (context, ref, child) {
                final provider = switch (value) {
                  ListenView.albums => ref.watch(
                      _isFavorites ? favoriteAlbumsProvider : albumsProvider,
                    ),
                  ListenView.artists => ref.watch(
                      _isFavorites ? favoriteArtistsProvider : artistsProvider,
                    ),
                  ListenView.playlists => ref.watch(
                      _isFavorites
                          ? favoritePlaylistsProvider
                          : playlistsProvider,
                    ),
                  ListenView.songs => ref.watch(favoriteSongsProvider),
                };

                return provider.when(
                  data: (state) {
                    if (state is List<SongDTO>) {
                      return ValueListenableBuilder(
                        valueListenable: _currentSong,
                        builder: (context, item, other) => SliverSongsList(
                          state,
                          selectedItem: item,
                          // onSelect: (song) => ref
                          //     .read(playbackProvider.notifier)
                          //     .play(song, _songs, widget.album),
                          onListUpdated: () =>
                              ref.invalidate(favoriteSongsProvider),
                        ),
                      );
                    }
                    if (state is ItemsPage) {
                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: _device.isTablet ? 360 : 200,
                          mainAxisSpacing: _device.isMobile ? 15 : 24,
                          crossAxisSpacing: _device.isMobile
                              ? 8
                              : (_device.isTablet ? 56 : 28),
                          childAspectRatio:
                              _device.isTablet ? 360 / 413 : 175 / 215.7,
                        ),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return AlbumView(
                            album: item,
                            onTap: (item) => switch (value) {
                              ListenView.albums => _onAlbumTap(item),
                              ListenView.artists => _onArtistTap(item),
                              ListenView.playlists => _onPlaylistTap(item),
                              ListenView.songs => null,
                            },
                            optionsBuilder: switch (value) {
                              ListenView.playlists => (context) => [
                                    PopupMenuItem(
                                      onTap: () => _onDeletePlaylist(item),
                                      child: const Text('Delete playlist'),
                                    ),
                                  ],
                              _ => null,
                            },
                          );
                        },
                        itemCount: state.items.length,
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                  error: (error, stackTrace) => SliverToBoxAdapter(
                    child: Text(error.toString()),
                  ),
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentView.dispose();
    _appliedFilter.dispose();
    _filterOpened.dispose();
    _currentSong.dispose();
    super.dispose();
  }

  Widget _pageViewToggle() {
    final availableTabs = !_isFavorites
        ? ListenView.values.where((tab) => tab != ListenView.songs)
        : ListenView.values;
    return ChipTheme(
      data: ChipTheme.of(context).copyWith(
        labelStyle: TextStyle(fontSize: _device.isMobile ? 14 : 16),
        padding: EdgeInsets.zero,
      ),
      child: Wrap(
        spacing: 12,
        children: [
          for (final value in availableTabs)
            ValueListenableBuilder(
              valueListenable: _currentView,
              builder: (context, currentView, child) => ActionChip(
                label: Text(_viewLabels[value] ?? '???'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: (value == currentView)
                    ? _theme.chipTheme.selectedColor
                    : _theme.chipTheme.backgroundColor,
                onPressed: () => _currentView.value = value,
              ),
            ),
        ],
      ),
    );
  }

  String _filterLabel(EntityFilter filter) {
    return _filtersLabels[filter] ?? '???';
  }

  List<EntityFilter> getFilterItems() => switch (_currentView.value) {
        ListenView.albums => EntityFilter.values.toList(),
        ListenView.artists => [
            EntityFilter.sortName,
            EntityFilter.dateCreated,
          ],
        ListenView.playlists => [
            EntityFilter.sortName,
            EntityFilter.dateCreated,
          ],
        ListenView.songs => [
            EntityFilter.sortName,
            EntityFilter.dateCreated,
          ],
      };

  void _applyProviderFilter(EntityFilter? value) {
    final filter = ref.read(filterProvider);
    if (filter.orderBy == value) {
      final desc = !filter.desc;
      ref.read(filterProvider.notifier).filter(value!, desc);
    } else {
      ref
          .read(filterProvider.notifier)
          .filter(value!, _defaultSorting[value] ?? false);
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
                        color: isOpened
                            ? _theme.colorScheme.primary
                            : _theme.iconTheme.color,
                      ),
                    ),
                  ),
                  buttonStyleData: const ButtonStyleData(
                    overlayColor: WidgetStatePropertyAll(Colors.transparent),
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
                                  color: (filter.orderBy == value)
                                      ? _theme.colorScheme.primary
                                      : _theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              filter.desc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: (filter.orderBy == value)
                                  ? _theme.colorScheme.primary
                                  : _theme.colorScheme.onPrimary,
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

  Widget _addButton() => ValueListenableBuilder(
        valueListenable: _currentView,
        builder: (context, currentView, child) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: switch (currentView) {
            ListenView.albums => const SizedBox.shrink(),
            ListenView.artists => const SizedBox.shrink(),
            ListenView.playlists => _isFavorites
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: _onCreateNewPlaylist,
                    icon: const Icon(Icons.add),
                  ),
            ListenView.songs => const SizedBox.shrink(),
          },
        ),
      );
}
