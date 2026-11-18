import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class TvBrowsePage extends ConsumerStatefulWidget {
  const TvBrowsePage({super.key});

  @override
  ConsumerState<TvBrowsePage> createState() => _TvBrowsePageState();
}

class _TvBrowsePageState extends ConsumerState<TvBrowsePage> {
  static const _songsPreview = 20;
  static const _searchDelay = Duration(milliseconds: 500);

  late ItemList _view;
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  final _searchField = FocusNode(debugLabel: 'browse:search-field');
  final _searchButton = FocusNode(debugLabel: 'browse:search');
  final _body = FocusNode(debugLabel: 'browse:body', skipTraversal: true);
  final Map<ItemList, FocusNode> _tabNodes = {
    for (final view in ItemList.values)
      view: FocusNode(debugLabel: 'browse:tab:${view.name}'),
  };
  Timer? _debounce;
  bool _bodyFocused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_trackFocus);
    _view =
        ref.read(browseViewRequestProvider) ??
        ref.read(defaultBrowseTabProvider);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(browseViewRequestProvider.notifier).state = null;
      if (ref.read(filterProvider) != _savedSort(_view)) _restoreSort(_view);
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_trackFocus);
    _debounce?.cancel();
    _searchController.dispose();
    _searchField.dispose();
    _searchButton.dispose();
    _body.dispose();
    for (final node in _tabNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _trackFocus() {
    final focus = FocusManager.instance.primaryFocus;
    final inBody = focus != null && focus.ancestors.contains(_body);
    if (inBody != _bodyFocused && mounted) {
      setState(() => _bodyFocused = inBody);
    }
  }

  void _onBack() {
    if (_searchOpen) {
      _closeSearch();
    } else {
      _tabNodes[_view]!.requestFocus();
    }
  }

  Filter _savedSort(ItemList view) {
    final saved = ref.read(browseSortProvider(view));
    final offered = view.sortOptions(
      albumRatingSort: ref.read(serverCapabilitiesProvider).albumRatingSort,
    );
    if (offered.contains(saved.orderBy)) return saved;
    return Filter(
      orderBy: view.defaultSortField,
      desc: view.defaultSortDescending,
    );
  }

  void _restoreSort(ItemList view) {
    final sort = _savedSort(view);
    ref
        .read(filterProvider.notifier)
        .filter(field: sort.orderBy, desc: sort.desc);
  }

  List<EntityFilter> _sortOptions(ItemList view) => view.sortOptions(
    albumRatingSort: ref.read(serverCapabilitiesProvider).albumRatingSort,
  );

  Future<void> _chooseSort() async {
    final view = _view;
    final current = ref.read(filterProvider);
    final chosen = await showDialog<EntityFilter>(
      context: context,
      builder: (context) => _SortDialog(
        options: _sortOptions(view),
        current: current,
      ),
    );
    if (chosen == null || !mounted) return;
    final next = ref.read(filterProvider).select(chosen);
    ref
        .read(filterProvider.notifier)
        .filter(field: next.orderBy, desc: next.desc);
    final serverId = ref.read(currentServerIdProvider);
    if (serverId == null) return;
    ref.read(appSettingsProvider.notifier).setBrowseSort(serverId, view, next);
  }

  void _selectView(ItemList view) {
    if (view == _view) return;
    setState(() => _view = view);
    _restoreSort(view);
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchField.requestFocus();
    });
  }

  void _closeSearch() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(searchProvider.notifier).state = null;
    setState(() => _searchOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchButton.requestFocus();
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      _searchDelay,
      () => _submitSearch(_searchController.text),
    );
  }

  void _submitSearch(String text) {
    _debounce?.cancel();
    final query = text.trim();
    ref.read(searchProvider.notifier).state = query.isEmpty ? null : query;
  }

  ImageProvider _image(LibraryItem item) =>
      ref.read(imageServiceProvider).itemImage(item, size: 400);

  void _open(LibraryItem item, ItemList view) {
    switch (view) {
      case ItemList.albums:
        unawaited(
          context.pushNamed(
            branchAwareName(context, Routes.album),
            extra: {'album': item},
          ),
        );
      case ItemList.artists:
        unawaited(
          context.pushNamed(
            branchAwareName(context, Routes.artist),
            extra: {'artist': item},
          ),
        );
      case ItemList.genres:
        unawaited(
          context.pushNamed(
            branchAwareName(context, Routes.genre),
            extra: {'genre': item},
          ),
        );
      case ItemList.playlists:
        ref.read(currentPlaylistProvider.notifier).setPlaylist(item);
        unawaited(
          context.pushNamed(
            branchAwareName(context, Routes.playlist),
            extra: {'playlist': item},
          ),
        );
      case ItemList.songs:
        break;
    }
  }

  Future<void> _playSong(LibraryItem song, List<LibraryItem> songs) async {
    final album = LibraryItem(
      id: song.albumId ?? song.id,
      name: song.albumName ?? '',
      kind: ItemKind.album,
      albumArtist: song.albumArtist,
      albumArtists: song.albumArtists,
      images: song.images,
    );
    await ref.read(playbackProvider.notifier).play(song, songs, album);
    if (mounted) unawaited(context.pushNamed(Routes.nowPlaying.name));
  }

  void _options(LibraryItem item, {required bool fromSearch}) => unawaited(
    showTvItemOptions(
      context,
      ref,
      item,
      scope: ContextMenuScope.browse,
      onLike: (item) async {
        final updated = await toggleFavourite(ref, item);
        if (fromSearch) {
          for (final category in searchCategories) {
            ref
                .read(searchItemsProvider(category).notifier)
                .updateItem(updated);
          }
        } else {
          ref.read(itemListProvider(_view).notifier).updateItem(updated);
        }
      },
    ),
  );

  String _label(ItemList view) =>
      view == ItemList.artists &&
          ref.watch(effectiveArtistScopeProvider) == ArtistScope.albumArtists
      ? 'Album Artists'
      : searchCategoryLabel(view);

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchProvider)?.trim() ?? '';
    final showResults = _searchOpen && query.isNotEmpty;

    return PopScope(
      canPop: !_searchOpen && !_bodyFocused,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TvTokens.pagePaddingH,
              TvTokens.pagePaddingV,
              TvTokens.pagePaddingH,
              0,
            ),
            child: Row(
              children: [
                for (final view in ItemList.values) ...[
                  _Tab(
                    label: _label(view),
                    selected: view == _view,
                    autofocus: view == _view,
                    focusNode: _tabNodes[view],
                    onSelect: () => _selectView(view),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                TvIconButton(
                  icon: Icons.sort_rounded,
                  size: 40,
                  iconSize: 20,
                  onSelect: () => unawaited(_chooseSort()),
                ),
                const SizedBox(width: 8),
                TvIconButton(
                  icon: _searchOpen ? JPlayer.close : JPlayer.search,
                  size: 40,
                  iconSize: 18,
                  selected: _searchOpen,
                  focusNode: _searchButton,
                  onSelect: _searchOpen ? _closeSearch : _openSearch,
                ),
              ],
            ),
          ),
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TvTokens.pagePaddingH,
                16,
                TvTokens.pagePaddingH,
                0,
              ),
              child: TvTextField(
                controller: _searchController,
                focusNode: _searchField,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
              ),
            ),
          Expanded(
            child: Focus(
              focusNode: _body,
              child: showResults
                  ? _results(query)
                  : _view == ItemList.songs
                  ? _songs()
                  : _grid(_view),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(ItemList view) {
    final list = ref.watch(itemListProvider(view));
    return list.when(
      data: (items) {
        if (items.isEmpty) return const _Message('Nothing here yet');
        return TvCardGrid(
          key: ValueKey(view),
          itemCount: items.length,
          itemAt: (index) {
            ref
                .read(itemListProvider(view).notifier)
                .touchPage(index ~/ items.pageSize);
            return items.itemAt(index);
          },
          imageFor: _image,
          subtitleFor: view == ItemList.albums
              ? (item) => item.albumArtist
              : null,
          circular: view == ItemList.artists,
          onSelect: (item) => _open(item, view),
          onLongSelect: (item) => _options(item, fromSearch: false),
        );
      },
      loading: () => const TvCardGrid.loading(),
      error: (error, _) => _error(),
    );
  }

  Widget _songs() {
    final list = ref.watch(itemListProvider(ItemList.songs));
    final playingId = ref.watch(barSongProvider.select((song) => song?.id));
    final images = ref.read(imageServiceProvider);
    return list.when(
      data: (items) {
        if (items.isEmpty) return const _Message('Nothing here yet');
        return FocusTraversalGroup(
          child: ListView.builder(
            key: const ValueKey(ItemList.songs),
            padding: const EdgeInsets.symmetric(
              horizontal: TvTokens.pagePaddingH - 16,
              vertical: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              ref
                  .read(itemListProvider(ItemList.songs).notifier)
                  .touchPage(index ~/ items.pageSize);
              final song = items.itemAt(index);
              if (song == null) return const _SongPlaceholder();
              return TvSongRow(
                song: song,
                cover: images.itemImage(song, size: 128),
                isPlaying: playingId == song.id,
                onSelect: () => unawaited(_playSong(song, items.items)),
                onLongSelect: () => _options(song, fromSearch: false),
              );
            },
          ),
        );
      },
      loading: () => const _SongsLoading(),
      error: (error, _) => _error(),
    );
  }

  Widget _results(String query) {
    final images = ref.read(imageServiceProvider);
    final playingId = ref.watch(barSongProvider.select((song) => song?.id));
    final results = {
      for (final category in searchCategories)
        category: ref.watch(searchItemsProvider(category)),
    };
    final settled = results.values.every((value) => value.hasValue);
    final empty =
        settled &&
        results.values.every(
          (value) => value.valueOrNull?.items.isEmpty ?? true,
        );
    if (empty) return _Message('No results for "$query"');
    final songs = results[ItemList.songs]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final category in searchCategories)
            if (category != ItemList.songs)
              TvShelf(
                title: _label(category),
                items: results[category]!.whenData((page) => page.items),
                imageFor: _image,
                subtitleFor: category == ItemList.albums
                    ? (item) => item.albumArtist
                    : null,
                circular: category == ItemList.artists,
                onSelect: (item) => _open(item, category),
                onLongSelect: (item) => _options(item, fromSearch: true),
              ),
          if (songs.valueOrNull?.items.isNotEmpty ?? false) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(
                TvTokens.pagePaddingH,
                0,
                TvTokens.pagePaddingH,
                8,
              ),
              child: Text('Songs', style: TvTokens.sectionTitle),
            ),
            FocusTraversalGroup(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TvTokens.pagePaddingH - 16,
                ),
                child: Column(
                  children: [
                    for (final song in songs.valueOrNull!.items.take(
                      _songsPreview,
                    ))
                      TvSongRow(
                        song: song,
                        cover: images.itemImage(song, size: 128),
                        isPlaying: playingId == song.id,
                        onSelect: () => unawaited(
                          _playSong(song, songs.valueOrNull!.items),
                        ),
                        onLongSelect: () => _options(song, fromSearch: true),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _error() => ref.watch(isOfflineProvider)
      ? const Padding(
          padding: EdgeInsets.all(TvTokens.pagePaddingH),
          child: OfflineNotice(
            message:
                "You're offline. Your library will be back "
                'once the server is reachable.',
          ),
        )
      : const _Message('Could not load this list');
}

class _SortDialog extends StatelessWidget {
  const _SortDialog({required this.options, required this.current});

  final List<EntityFilter> options;
  final Filter current;

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            for (final option in options)
              TvOptionRow(
                icon: Icon(
                  option == current.orderBy
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                label: Text(option.label),
                trailing: option == current.orderBy
                    ? Icon(
                        current.desc
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 18,
                      )
                    : null,
                autofocus: option == current.orderBy,
                onSelect: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onSelect,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final bool selected;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return TvFocusable(
      onSelect: onSelect,
      autofocus: autofocus,
      focusNode: focusNode,
      scrollOnFocus: false,
      debugLabel: 'browse:$label',
      builder: (context, focused) => AnimatedContainer(
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: focused ? Colors.white : (selected ? accent : Colors.white12),
          borderRadius: BorderRadius.circular(999),
          boxShadow: focused ? TvTokens.glow(alpha: 0.25) : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: focused ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(TvTokens.pagePaddingH),
    child: Align(
      alignment: Alignment.topLeft,
      child: Text(text, style: TvTokens.caption),
    ),
  );
}

class _SongPlaceholder extends StatelessWidget {
  const _SongPlaceholder();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        SizedBox(width: 40),
        ShimmerBox(width: 40, height: 40),
        SizedBox(width: 12),
        ShimmerBox(width: 220, height: 14),
      ],
    ),
  );
}

class _SongsLoading extends StatelessWidget {
  const _SongsLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(
      horizontal: TvTokens.pagePaddingH - 16,
      vertical: 16,
    ),
    physics: const NeverScrollableScrollPhysics(),
    children: [for (var i = 0; i < 8; i++) const _SongPlaceholder()],
  );
}
