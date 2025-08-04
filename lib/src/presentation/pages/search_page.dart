import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchFieldController = TextEditingController();
  late final _currentView = ValueNotifier<SearchView>(SearchView.all);
  Timer? _debounce;

  late ThemeData _theme;
  late DeviceType _device;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).state = query;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  Map<SearchView, String> get _viewLabels => {
    SearchView.all: 'All',
    SearchView.playlists: 'Playlists',
    SearchView.albums: 'Albums',
    SearchView.artists: 'Artists',
    SearchView.songs: 'Songs',
  };

  Widget _pageViewToggle() => ChipTheme(
    data: ChipTheme.of(context).copyWith(
      labelStyle: TextStyle(fontSize: _device.isMobile ? 14 : 16),
    ),
    child: Wrap(
      spacing: 12,
      children: [
        for (final value in SearchView.values)
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

  @override
  Widget build(BuildContext context) {
    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(_device.isMobile ? 60 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _device.isMobile ? 16 : 30),
          child: Flex(
            direction: _device.isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: _device.isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Offstage(
                offstage: _device.isMobile,
                child: _titleText(),
              ),
              SizedBox(width: _device.isTablet ? 36 : 44),
              if (_device.isMobile)
                _searchField()
              else
                Expanded(child: _searchField()),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: _device.isMobile ? 16 : 30,
        right: _device.isMobile ? 16 : 30,
        bottom: _device.isDesktop ? 30 : 16,
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _pageViewToggle(),
        ),
        SliverToBoxAdapter(
          child: ValueListenableBuilder(
            valueListenable: _currentView,
            builder: (context, value, child) {
              if (value != SearchView.all &&
                  value != SearchView.albums &&
                  value != SearchView.playlists) {
                return const SizedBox.shrink();
              }
              return Consumer(
                builder: (context, ref, child) {
                  final albums = ref.watch(searchAlbumsProvider);
                  if (albums.valueOrNull?.items.isEmpty ?? true) {
                    return const SizedBox.shrink();
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Albums',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                },
              );
            },
          ),
        ),
        albums,
        SliverToBoxAdapter(
          child: ValueListenableBuilder(
            valueListenable: _currentView,
            builder: (context, value, child) {
              if (value != SearchView.all && value != SearchView.artists) {
                return const SizedBox.shrink();
              }
              return Consumer(
                builder: (context, ref, child) {
                  final artists = ref.watch(searchArtistsProvider);
                  if (artists.valueOrNull?.items.isEmpty ?? true) {
                    return const SizedBox.shrink();
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Artists',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                },
              );
            },
          ),
        ),
        artists,
        SliverToBoxAdapter(
          child: SizedBox(
            height: _device.isDesktop ? 40 : (_device.isMobile ? 28 : 30),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget _titleText() => Text(
    'Search',
    style: TextStyle(
      fontSize: _device.isMobile ? 24 : 36,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
  );

  Widget get artists => ValueListenableBuilder(
    valueListenable: _currentView,
    builder: (context, value, child) {
      if (value != SearchView.artists && value != SearchView.all) {
        return const SliverPadding(
          padding: EdgeInsets.zero,
        );
      }

      return Consumer(
        builder: (context, ref, child) {
          final artists =
              ref.watch(searchArtistsProvider).valueOrNull?.items ?? const [];

          int firstRowCount;

          if (_device.isDesktop || _device.isTablet) {
            final screenWidth = _device.screenSize.width - 290;
            final maxExtent = _device.isTablet ? 360 : 200;
            firstRowCount = (screenWidth / maxExtent).floor();
          } else {
            firstRowCount =
                2; // As per your SliverGridDelegateWithFixedCrossAxisCount
          }

          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _device.isTablet ? 360 : 200,
              mainAxisSpacing: _device.isMobile ? 15 : 24,
              crossAxisSpacing: _device.isMobile
                  ? 8
                  : (_device.isTablet ? 56 : 28),
              childAspectRatio: _device.isTablet ? 0.8 : 175 / 215.7,
            ),
            itemBuilder: (context, index) => AlbumView(
              album: artists[index],
              onTap: (artist) => context.pushNamed(
                Routes.artist.name,
                extra: {'artist': artist},
              ),
            ),
            itemCount: value == SearchView.albums
                ? artists.length
                : min(firstRowCount, artists.length),
          );
        },
      );
    },
  );

  Widget get albums => ValueListenableBuilder(
    valueListenable: _currentView,
    builder: (context, value, child) {
      if (value != SearchView.all &&
          value != SearchView.albums &&
          value != SearchView.playlists) {
        return const SliverPadding(
          padding: EdgeInsets.zero,
        );
      }

      return Consumer(
        builder: (context, ref, child) {
          final albums =
              ref.watch(searchAlbumsProvider).valueOrNull?.items ?? const [];

          int firstRowCount;

          if (_device.isDesktop || _device.isTablet) {
            final screenWidth = MediaQuery.of(context).size.width - 290;
            final maxExtent = _device.isTablet ? 360 : 200;
            firstRowCount = (screenWidth / maxExtent).floor();
          } else {
            firstRowCount = 2;
          }

          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _device.isTablet ? 360 : 200,
              mainAxisSpacing: _device.isMobile ? 15 : 24,
              crossAxisSpacing: _device.isMobile
                  ? 8
                  : (_device.isTablet ? 56 : 28),
              childAspectRatio: _device.isTablet ? 0.8 : 175 / 215.7,
            ),
            itemBuilder: (context, index) => AlbumView(
              album: albums[index],
              showArtist: false,
              onTap: (album) {
                ref.read(currentAlbumProvider.notifier).setAlbum(album);
                context.pushNamed(
                  Routes.album.name,
                  extra: {'album': album},
                );
              },
            ),
            itemCount: value == SearchView.albums
                ? albums.length
                : min(firstRowCount, albums.length),
          );
        },
      );
    },
  );

  Widget _searchField() => TextField(
    onChanged: _onSearchChanged,
    controller: _searchFieldController,
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.search,
    style: const TextStyle(
      fontSize: 16,
      height: 1.2,
    ),
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
        onPressed: _searchFieldController.clear,
        padding: EdgeInsets.zero,
        icon: const Icon(JPlayer.close),
      ),
      hintText: _device.isMobile ? 'Search' : null,
    ),
  );
}
