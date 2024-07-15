import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_album_provider.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchFieldController = TextEditingController();
  late final ValueNotifier<SearchView> _currentView =
      ValueNotifier(SearchView.all);
  Timer? _debounce;

  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;
  late bool _isDesktop;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).state = query;
    });
  }

  late ThemeData _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.sizeOf(context);
    _theme = Theme.of(context);
    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isTablet = deviceType == DeviceScreenType.tablet;
    _isDesktop = deviceType == DeviceScreenType.desktop;
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
          labelStyle: TextStyle(fontSize: _isMobile ? 14 : 16),
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
        preferredSize: Size.fromHeight(_isMobile ? 60 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 30),
          child: Flex(
            direction: _isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: _isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Offstage(
                offstage: _isMobile,
                child: _titleText(),
              ),
              SizedBox(width: _isTablet ? 36 : 44),
              if (_isMobile)
                _searchField()
              else
                Expanded(child: _searchField()),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: _isMobile ? 16 : 30,
        right: _isMobile ? 16 : 30,
        bottom: _isDesktop ? 30 : 16,
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
                  final albums = ref.watch(searchAlbumProvider);
                  return albums.value.items.isNotEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Albums', style: TextStyle(fontSize: 18)),
                        )
                      : const SizedBox.shrink();
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
                  return artists.value.items.isNotEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child:
                              Text('Artists', style: TextStyle(fontSize: 18)),
                        )
                      : const SizedBox.shrink();
                },
              );
            },
          ),
        ),
        artists,
        SliverToBoxAdapter(
          child: SizedBox(
            height: _isDesktop ? 40 : (_isMobile ? 28 : 30),
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
          fontSize: _isMobile ? 24 : 36,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );

  int get maxItemsInRow {
    return calculateMaxItemsInRow(_isTablet ? 360 : 200, _isMobile ? 15 : 24);
  }

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
              final artists = ref.watch(searchArtistsProvider);

              int firstRowCount;

              if (_isDesktop || _isTablet) {
                final screenWidth = MediaQuery.of(context).size.width - 290;
                final maxExtent = _isTablet ? 360 : 200;
                firstRowCount = (screenWidth / maxExtent).floor();
              } else {
                firstRowCount =
                    2; // As per your SliverGridDelegateWithFixedCrossAxisCount
              }

              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _isTablet ? 360 : 200,
                  mainAxisSpacing: _isMobile ? 15 : 24,
                  crossAxisSpacing: _isMobile ? 8 : (_isTablet ? 56 : 28),
                  childAspectRatio: _isTablet ? 0.8 : 175 / 215.7,
                ),
                itemBuilder: (context, index) {
                  return AlbumView(
                    album: artists.value.items[index],
                    onTap: () {
                      final location = GoRouterState.of(context).fullPath;
                      context.go(
                        '$location${Routes.artist}',
                        extra: {'artist': artists.value.items[index]},
                      );
                    },
                  );
                },
                itemCount: value == SearchView.albums
                    ? artists.value.items.length
                    : min(firstRowCount, artists.value.items.length),
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
              final albums = ref.watch(searchAlbumProvider);

              int firstRowCount;

              if (_isDesktop || _isTablet) {
                final screenWidth = MediaQuery.of(context).size.width - 290;
                final maxExtent = _isTablet ? 360 : 200;
                firstRowCount = (screenWidth / maxExtent).floor();
              } else {
                firstRowCount = 2;
              }

              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _isTablet ? 360 : 200,
                  mainAxisSpacing: _isMobile ? 15 : 24,
                  crossAxisSpacing: _isMobile ? 8 : (_isTablet ? 56 : 28),
                  childAspectRatio: _isTablet ? 0.8 : 175 / 215.7,
                ),
                itemBuilder: (context, index) {
                  return AlbumView(
                    album: albums.value.items[index],
                    showArtist: false,
                    onTap: () {
                      final location = GoRouterState.of(context).fullPath;
                      ref
                          .read(currentAlbumProvider.notifier)
                          .setAlbum(albums.value.items[index]);
                      context.go(
                        '$location${Routes.album}',
                        extra: {'album': albums.value.items[index]},
                      );
                    },
                  );
                },
                itemCount: value == SearchView.albums
                    ? albums.value.items.length
                    : min(firstRowCount, albums.value.items.length),
              );
            },
          );
        },
      );
  int calculateMaxItemsInRow(double itemWidth, double spacing) {
    final screenWidth =
        MediaQuery.of(context).size.width - 240; // 240 is the width of sidebar
    return (screenWidth / (itemWidth + spacing)).floor();
  }

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
          hintText: _isMobile ? 'Search' : null,
        ),
      );
}
