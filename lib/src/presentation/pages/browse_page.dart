import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/desktop/create_desktop_playlist_form.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

class BrowsePage extends ConsumerStatefulWidget {
  const BrowsePage({super.key});

  @override
  ConsumerState<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends ConsumerState<BrowsePage>
    with SingleTickerProviderStateMixin {
  static const _searchButtonWidth = 48.0;
  static const _searchDismissScrollDistance = 64.0;
  static const _searchFieldHeight = 42.0;
  static const _iconRowHeight = 48.0;
  static const _chipsRowHeight = 48.0;
  static const _barRowsSpacing = 4.0;
  static const _bellIconSize = 28.0;
  late final ValueNotifier<ItemList> _currentView;
  late final Map<EntityFilter, bool> _availableFilters;
  late final ValueNotifier<Filter> _appliedFilter;
  final _filterOpened = ValueNotifier<bool>(false);
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchOpened = ValueNotifier<bool>(false);
  final _searchQuery = ValueNotifier<String>('');
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  double _scrolledSinceSearchOpened = 0;

  late final AnimationController _searchAnimation = AnimationController(
    duration: const Duration(milliseconds: 260),
    vsync: this,
  );
  late final Animation<double> _searchExpansion = CurvedAnimation(
    parent: _searchAnimation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late ThemeData _theme;
  late DeviceType _device;

  Map<ItemList, String> get _viewLabels => {
    ItemList.albums: 'Albums',
    ItemList.artists: 'Artists',
    ItemList.genres: 'Genres',
    ItemList.playlists: 'Playlists',
    ItemList.songs: 'Songs',
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

  void _onAlbumTap(LibraryItem album) {
    ref.read(currentAlbumProvider.notifier).setAlbum(album);
    context.pushNamed(
      Routes.album.name,
      extra: {'album': album},
    );
  }

  void _onArtistTap(LibraryItem artist) => context.pushNamed(
    Routes.artist.name,
    extra: {'artist': artist},
  );

  void _onGenreTap(LibraryItem genre) => context.pushNamed(
    Routes.genre.name,
    extra: {'genre': genre},
  );

  void _onPlaylistTap(LibraryItem playlist) {
    ref.read(currentPlaylistProvider.notifier).setPlaylist(playlist);
    context.pushNamed(
      Routes.playlist.name,
      extra: {'playlist': playlist},
    );
  }

  Future<void> _onSongGoToAlbum(LibraryItem song) async {
    final albumId = song.albumId;
    if (albumId == null) return;
    final item = await ref.read(mediaServerClientProvider).getItem(albumId);
    if (!mounted) return;
    _onAlbumTap(item);
  }

  Future<void> _onSongArtistTap(LibraryItem song) async {
    final artistId = song.albumArtists.firstOrNull?.id;
    if (artistId == null) return;
    final item = await ref.read(mediaServerClientProvider).getItem(artistId);
    if (!mounted) return;
    context.pushNamed(Routes.artist.name, extra: {'artist': item});
  }

  Future<void> _onPlaySetPressed(LibraryItem item, ItemList view) async {
    final notifier = ref.read(setPlaybackProvider.notifier);
    try {
      final result = await switch (view) {
        ItemList.albums => notifier.playAlbum(item),
        ItemList.artists => notifier.playArtist(item),
        ItemList.genres => notifier.playGenre(item),
        ItemList.playlists => notifier.playPlaylist(item),
        ItemList.songs => Future.value(SetPlaybackResult.busy),
      };
      if (result == SetPlaybackResult.empty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nothing to play in "${item.name}"')),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start playing "${item.name}"')),
        );
      }
    }
  }

  void _onSongTap(LibraryItem song, List<LibraryItem> allSongs) {
    final syntheticAlbum = LibraryItem(
      id: song.albumId ?? song.id,
      name: song.albumName ?? '',
      kind: ItemKind.album,
      albumArtist: song.albumArtist,
      albumArtists: song.albumArtists,
      images: song.images,
    );
    ref.read(playbackProvider.notifier).play(song, allSongs, syntheticAlbum);
  }

  Future<void> _onLikePressed(LibraryItem song) async {
    final isFavorite = song.userData.isFavorite;
    await ref
        .read(mediaServerClientProvider)
        .setFavorite(song.id, favorite: !isFavorite);
    ref
        .read(itemListProvider(ItemList.songs).notifier)
        .updateItem(
          song.copyWith(
            userData: song.userData.copyWith(isFavorite: !isFavorite),
          ),
        );
  }

  Future<void> _onAddToPlaylistPressed(LibraryItem song) async {
    final playlist = await showPlaylistPicker(
      context,
      isDesktop: _device.isDesktop,
    );
    if (playlist != null && mounted) {
      await ref
          .read(mediaServerClientProvider)
          .addPlaylistItems(playlistId: playlist.id, itemIds: [song.id]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully added to playlist')),
        );
      }
    }
  }

  void _onCreateNewPlaylist() {
    if (_device.isDesktop) {
      showAdaptiveDialog<void>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: CreateDesktopPlaylistForm(
                onCreated: () => ref.invalidate(playlistsProvider),
              ),
            ),
          ),
        ),
      );
    } else {
      PersistentBottomSheetController? controller;
      // _scaffoldKey.currentState?.showBodyScrim(true, 0.66);
      showModalBottomSheet<void>(
        useRootNavigator: true,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CloseButton(onPressed: () => Navigator.of(context).pop()),
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

  Future<void> _onDeletePlaylist(LibraryItem playlist) async {
    final shouldDelete = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
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
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if ((shouldDelete ?? false) && mounted) {
      await ref
          .read(mediaServerClientProvider)
          .deletePlaylist(playlist.id);
      ref.invalidate(playlistsProvider);
    }
  }

  double get _navigationBarHeight => _device.isMobile
      ? _iconRowHeight + _barRowsSpacing + _chipsRowHeight
      : 100;

  double get _searchTrailingWidth =>
      _device.isMobile ? _searchButtonWidth + 40 : 40 + 12 + 40;

  void _openSearch() {
    _searchOpened.value = true;
    _scrolledSinceSearchOpened = 0;
    _searchAnimation.forward().then((_) {
      if (mounted && _searchOpened.value) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_searchOpened.value) return;
    _searchDebounce?.cancel();
    _searchOpened.value = false;
    _searchQuery.value = '';
    _searchController.clear();
    _searchFocusNode.unfocus();
    ref.read(searchProvider.notifier).state = null;
    _searchAnimation.reverse();
  }

  void _onSearchChanged(String query) {
    _searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).state = query.trim();
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        notification.metrics.axis != Axis.vertical ||
        !_searchOpened.value ||
        _searchController.text.isNotEmpty) {
      return false;
    }

    final delta = notification.scrollDelta ?? 0;
    if (delta == 0) return false;

    if (delta.isNegative != _scrolledSinceSearchOpened.isNegative) {
      _scrolledSinceSearchOpened = 0;
    }
    _scrolledSinceSearchOpened += delta;

    if (_scrolledSinceSearchOpened.abs() >= _searchDismissScrollDistance) {
      _closeSearch();
    }
    return false;
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      _closeSearch();
    }
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _currentView = ValueNotifier(ItemList.values.first)
      ..addListener(() {
        final view = _currentView.value;
        ref
            .read(filterProvider.notifier)
            .filter(
              field: view.defaultSortField,
              desc: view.defaultSortDescending,
            );
      });
    _availableFilters = {
      for (final value in EntityFilter.values) value: false,
    };
    _appliedFilter = ValueNotifier(Filter(orderBy: EntityFilter.values.first))
      ..addListener(
        () => ref
            .read(filterProvider.notifier)
            .filter(
              field: _appliedFilter.value.orderBy,
              desc: _appliedFilter.value.desc,
            ),
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
      key: _scaffoldKey,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: ScrollablePageScaffold(
          useGradientBackground: true,
          navigationBar: PreferredSize(
            preferredSize: Size.fromHeight(_navigationBarHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _device.isMobile ? 16 : 30,
              ),
              child: _navigationBarContent(),
            ),
          ),
          loadMoreData: () => _searchQuery.value.isNotEmpty
              ? Future<void>.value()
              : ref
                    .read(itemListProvider(_currentView.value).notifier)
                    .loadMore(),
          contentPadding: EdgeInsets.only(
            left: _device.isMobile ? 16 : 30,
            right: _device.isMobile ? 16 : 30,
            bottom: 30,
          ),
          slivers: [
            ValueListenableBuilder(
              valueListenable: _searchQuery,
              builder: (context, query, child) =>
                  query.isEmpty ? _libraryList() : const SearchResultsSliver(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _libraryList() => ValueListenableBuilder(
    valueListenable: _currentView,
    builder: (context, value, child) => Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(itemListProvider(value));
        return provider.when(
          data: (list) {
            if (value == ItemList.songs) {
              final currentSongId = ref.watch(
                playbackProvider.select((s) {
                  final idx = s.currentMediaIndex;
                  return idx != null ? s.songs.elementAtOrNull(idx)?.id : null;
                }),
              );
              return SliverList.builder(
                itemBuilder: (context, index) {
                  final song = list.items[index];
                  return SongRowView(
                    song: song,
                    isPlaying: currentSongId == song.id,
                    onTap: (song) => _onSongTap(song, list.items),
                    onLikePressed: _onLikePressed,
                    onArtistTap: _onSongArtistTap,
                    optionsBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () => _onAddToPlaylistPressed(song),
                        child: const Text('Add to playlist'),
                      ),
                      if (song.albumArtists.isNotEmpty)
                        PopupMenuItem(
                          onTap: () => _onSongArtistTap(song),
                          child: const Text('Go to Artist'),
                        ),
                      if (song.albumId != null)
                        PopupMenuItem(
                          onTap: () => _onSongGoToAlbum(song),
                          child: const Text('Go to Album'),
                        ),
                    ],
                  );
                },
                itemCount: list.items.length,
              );
            }
            return SliverGrid.builder(
              gridDelegate: AlbumCardMetrics.gridDelegate(_device),
              itemBuilder: (context, index) {
                final item = list.items[index];
                return AlbumView(
                  album: item,
                  onTap: (item) => switch (value) {
                    ItemList.albums => _onAlbumTap(item),
                    ItemList.artists => _onArtistTap(item),
                    ItemList.genres => _onGenreTap(item),
                    ItemList.playlists => _onPlaylistTap(item),
                    ItemList.songs => null,
                  },
                  onPlayPressed: (value == ItemList.songs)
                      ? null
                      : (item) => _onPlaySetPressed(item, value),
                  optionsBuilder: switch (value) {
                    ItemList.playlists => (context) => [
                      PopupMenuItem(
                        onTap: () => _onDeletePlaylist(item),
                        child: const Text('Delete playlist'),
                      ),
                    ],
                    _ => null,
                  },
                );
              },
              itemCount: list.items.length,
            );
          },
          error: (error, stackTrace) => SliverToBoxAdapter(
            child: ref.watch(isOfflineProvider)
                ? OfflineNotice(
                    message:
                        "You're offline. Your library will be back "
                        'once the server is reachable.',
                    onRetry: () => ref.invalidate(itemListProvider(value)),
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
  );

  @override
  void dispose() {
    _currentView.dispose();
    _appliedFilter.dispose();
    _filterOpened.dispose();
    _searchDebounce?.cancel();
    _searchAnimation.dispose();
    _searchOpened.dispose();
    _searchQuery.dispose();
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    super.dispose();
  }

  Widget _pageViewToggle() => ChipTheme(
    data: ChipTheme.of(context).copyWith(
      labelStyle: TextStyle(fontSize: _device.isMobile ? 14 : 16),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12,
        children: [
          for (final value in ItemList.values)
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
    ),
  );

  Widget _libraryAvatar(LibraryItem? library, double size) {
    final tag = library?.images.primary;
    final image = (tag != null)
        ? ref.read(imageServiceProvider).albumIP(tagId: tag, id: library!.id)
        : null;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _theme.colorScheme.surface,
      backgroundImage: image,
      child: image == null ? Icon(Icons.library_music, size: size / 2) : null,
    );
  }

  Widget _libraryButton() {
    final current = ref.watch(currentLibraryProvider).valueOrNull;
    final libraries =
        ref.watch(librariesProvider).valueOrNull ?? const <LibraryItem>[];
    final size = _device.isMobile ? 32.0 : 40.0;

    // The library restored from prefs carries no imageTags, so resolve the
    // full DTO from librariesProvider (by id) to show the real cover image.
    final selected = libraries.cast<LibraryItem?>().firstWhere(
      (l) => l?.id == current?.id,
      orElse: () => null,
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton2<LibraryItem>(
        customButton: _libraryAvatar(selected ?? current, size),
        buttonStyleData: const ButtonStyleData(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
        dropdownStyleData: DropdownStyleData(
          width: 220,
          padding: const EdgeInsets.all(8),
          offset: const Offset(0, -8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        ),
        items: [
          for (final lib in libraries)
            DropdownMenuItem<LibraryItem>(
              value: lib,
              child: Row(
                children: [
                  _libraryAvatar(lib, 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lib.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        color: (lib.id == current?.id)
                            ? _theme.colorScheme.primary
                            : _theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        value: selected,
        onChanged: (lib) {
          if (lib != null) {
            ref.read(currentLibraryProvider.notifier).setLibrary(lib);
          }
        },
      ),
    );
  }

  String _filterLabel(EntityFilter filter) {
    return _filtersLabels[filter] ?? '???';
  }

  List<EntityFilter> getFilterItems() => switch (_currentView.value) {
    ItemList.albums => EntityFilter.values.toList(),
    ItemList.artists => const [
      EntityFilter.sortName,
      EntityFilter.dateCreated,
    ],
    ItemList.genres => const [
      EntityFilter.sortName,
    ],
    ItemList.playlists => const [
      EntityFilter.sortName,
      EntityFilter.dateCreated,
    ],
    ItemList.songs => const [
      EntityFilter.sortName,
      EntityFilter.dateCreated,
      EntityFilter.albumArtist,
      EntityFilter.random,
    ],
  };

  void _applyProviderFilter(EntityFilter? value) {
    final filter = ref.read(filterProvider);
    if (filter.orderBy == value) {
      ref
          .read(filterProvider.notifier)
          .filter(field: value!, desc: !filter.desc);
    } else {
      ref
          .read(filterProvider.notifier)
          .filter(field: value!, desc: _defaultSorting[value] ?? false);
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

  Widget _navigationBarContent() => LayoutBuilder(
    builder: (context, constraints) {
      final fullWidth = constraints.maxWidth;
      final collapsedLeft =
          fullWidth - _searchTrailingWidth - _searchButtonWidth;
      final collapsedTop = _device.isMobile
          ? (_iconRowHeight - _searchFieldHeight) / 2
          : (_navigationBarHeight - _searchFieldHeight) / 2;
      final expandedTop = (_navigationBarHeight - _searchFieldHeight) / 2;

      return AnimatedBuilder(
        animation: _searchExpansion,
        builder: (context, child) {
          final progress = _searchExpansion.value.clamp(0.0, 1.0);
          return Stack(
            children: [
              if (progress < 1)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: progress > 0,
                    child: Opacity(
                      opacity: 1 - progress,
                      child: _device.isMobile
                          ? _mobileBarRows()
                          : _desktopBarRow(),
                    ),
                  ),
                ),
              if (progress > 0)
                Positioned(
                  left: collapsedLeft * (1 - progress),
                  right: _searchTrailingWidth * (1 - progress),
                  top: collapsedTop + (expandedTop - collapsedTop) * progress,
                  height: _searchFieldHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: progress < 1
                        ? _collapsingSearchField()
                        : _searchField(),
                  ),
                ),
            ],
          );
        },
      );
    },
  );

  Widget _desktopBarRow() => Row(
    children: [
      Expanded(child: _pageViewToggle()),
      _addButton(),
      _searchButton(),
      _filterButton(),
      const SizedBox(width: 12),
      _libraryButton(),
    ],
  );

  Widget _mobileBarRows() => Column(
    children: [
      SizedBox(
        height: _iconRowHeight,
        child: Row(
          children: [
            _libraryButton(),
            const Spacer(),
            _addButton(),
            _searchButton(),
            _filterButton(),
            IconTheme.merge(
              data: const IconThemeData(size: _bellIconSize),
              child: UpdatifyTrigger(
                projectId: updatifyProjectId,
                popupType: UpdatifyPopupType.bottomSheet,
                backgroundColor: Themes.changelogSurface,
                borderRadius: BorderRadius.circular(8),
                width: _device.isDesktop
                    ? MediaQuery.sizeOf(context).width / 2
                    : double.infinity,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: _barRowsSpacing),
      SizedBox(
        height: _chipsRowHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: _pageViewToggle(),
        ),
      ),
    ],
  );

  Widget _searchButton() => IconButton(
    onPressed: _openSearch,
    icon: const Icon(JPlayer.search),
  );

  Widget _collapsingSearchField() => Container(
    height: 42,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white.withOpacity(0.24),
    child: const Icon(JPlayer.search),
  );

  Widget _searchField() => TextField(
    controller: _searchController,
    focusNode: _searchFocusNode,
    onChanged: _onSearchChanged,
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.search,
    style: const TextStyle(fontSize: 16, height: 1.2),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.24),
      isDense: true,
      contentPadding: const EdgeInsets.all(9),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(40),
      ),
      prefixIcon: const Icon(JPlayer.search),
      suffixIcon: IconButton(
        onPressed: () {
          if (_searchController.text.isEmpty) {
            _closeSearch();
          } else {
            _searchController.clear();
            _onSearchChanged('');
          }
        },
        padding: EdgeInsets.zero,
        icon: const Icon(JPlayer.close),
      ),
      hintText: 'Search',
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
        ItemList.playlists => IconButton(
          onPressed: _onCreateNewPlaylist,
          icon: const Icon(Icons.add),
        ),
        _ => const SizedBox.shrink(),
      },
    ),
  );
}
