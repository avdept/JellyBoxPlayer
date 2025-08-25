import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/desktop/create_desktop_playlist_form.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class ListenPage extends ConsumerStatefulWidget {
  const ListenPage({super.key});

  @override
  ConsumerState<ListenPage> createState() => _ListenPageState();
}

class _ListenPageState extends ConsumerState<ListenPage> {
  late final ValueNotifier<ItemList> _currentView;
  late final Map<EntityFilter, bool> _availableFilters;
  late final ValueNotifier<Filter> _appliedFilter;
  final _filterOpened = ValueNotifier<bool>(false);
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late ThemeData _theme;
  late DeviceType _device;

  Map<ItemList, String> get _viewLabels => {
    ItemList.albums: 'Albums',
    ItemList.artists: 'Artists',
    ItemList.playlists: 'Playlists',
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
    ref.read(currentAlbumProvider.notifier).setAlbum(album);
    context.pushNamed(
      Routes.album.name,
      extra: {'album': album},
    );
  }

  void _onArtistTap(ItemDTO artist) => context.pushNamed(
    Routes.artist.name,
    extra: {'artist': artist},
  );

  void _onPlaylistTap(ItemDTO playlist) {
    ref.read(currentPlaylistProvider.notifier).setPlaylist(playlist);
    context.pushNamed(
      Routes.playlist.name,
      extra: {'playlist': playlist},
    );
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

  Future<void> _onDeletePlaylist(ItemDTO playlist) async {
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
          .read(jellyfinApiProvider)
          .deletePlaylist(playlistId: playlist.id);
      ref.invalidate(playlistsProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentView = ValueNotifier(ItemList.values.first)
      ..addListener(
        () => _appliedFilter.value = Filter(
          orderBy: _currentView.value == ItemList.albums
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
                _pageViewToggle(),
                const Spacer(),
                _addButton(),
                _filterButton(),
              ],
            ),
          ),
        ),
        loadMoreData: ref
            .read(itemListProvider(_currentView.value).notifier)
            .loadMore,
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
                final provider = ref.watch(itemListProvider(value));
                return provider.when(
                  data: (list) => SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: _device.isTablet ? 360 : 200,
                      mainAxisSpacing: _device.isMobile ? 15 : 24,
                      crossAxisSpacing: _device.isMobile
                          ? 8
                          : (_device.isTablet ? 56 : 28),
                      childAspectRatio: _device.isTablet
                          ? 360 / 413
                          : 175 / 215.7,
                    ),
                    itemBuilder: (context, index) {
                      final item = list.items[index];
                      return AlbumView(
                        album: item,
                        onTap: (item) => switch (value) {
                          ItemList.albums => _onAlbumTap(item),
                          ItemList.artists => _onArtistTap(item),
                          ItemList.playlists => _onPlaylistTap(item),
                        },
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
                  ),
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
    super.dispose();
  }

  Widget _pageViewToggle() => ChipTheme(
    data: ChipTheme.of(context).copyWith(
      labelStyle: TextStyle(fontSize: _device.isMobile ? 14 : 16),
    ),
    child: Wrap(
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
  );

  String _filterLabel(EntityFilter filter) {
    return _filtersLabels[filter] ?? '???';
  }

  List<EntityFilter> getFilterItems() => switch (_currentView.value) {
    ItemList.albums => EntityFilter.values.toList(),
    ItemList.artists => const [
      EntityFilter.sortName,
      EntityFilter.dateCreated,
    ],
    ItemList.playlists => const [
      EntityFilter.sortName,
      EntityFilter.dateCreated,
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
