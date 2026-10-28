import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class ArtistPage extends ConsumerStatefulWidget {
  const ArtistPage({required this.artist, super.key});
  final LibraryItem artist;

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
  final _scrollController = ScrollController();
  final _titleOpacity = ValueNotifier<double>(0);
  final _titleKey = GlobalKey(debugLabel: 'title');
  List<LibraryItem> _albums = [];
  List<LibraryItem> _appearsOn = [];
  late LibraryItem _artist = widget.artist;

  late Size _screenSize;
  late ThemeData _theme;
  late DeviceType _device;

  void _onScroll() {
    final titleContext = _titleKey.currentContext;

    if (titleContext?.mounted ?? false) {
      final scrollPosition = _scrollController.position;
      final scrollableContext = scrollPosition.context.notificationContext!;
      final scrollableRenderBox =
          scrollableContext.findRenderObject()! as RenderBox;
      final titleRenderBox = titleContext!.findRenderObject()! as RenderBox;
      final titlePosition = titleRenderBox.localToGlobal(
        Offset.zero,
        ancestor: scrollableRenderBox,
      );
      final titleHeight = titleContext.size!.height;
      final visibleFraction = (titlePosition.dy + titleHeight) / titleHeight;
      _titleOpacity.value = 1 - min(max(visibleFraction, 0), 1);
    }
  }

  @override
  void initState() {
    super.initState();
    _getAlbums();
    _getAppearsOn();
    _refreshArtist();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _refreshArtist() async {
    final LibraryItem fresh;
    try {
      fresh = await ref
          .read(mediaServerClientProvider)
          .getItem(widget.artist.id, kind: ItemKind.artist);
    } on Object {
      return;
    }
    if (!mounted || fresh.overview == null) return;
    setState(() => _artist = fresh);
  }

  Future<void> _onAlbumLikePressed(LibraryItem album) async {
    final updated = await toggleFavourite(ref, album);
    if (!mounted) return;
    LibraryItem replace(LibraryItem item) =>
        item.id == updated.id ? updated : item;
    setState(() {
      _albums = _albums.map(replace).toList();
      _appearsOn = _appearsOn.map(replace).toList();
    });
  }

  Future<void> _getAppearsOn() async {
    final resp = await ref
        .read(mediaServerClientProvider)
        .getAlbums(
          LibraryQuery(
            sort: ItemSort.releaseDate,
            direction: SortDirection.descending,
            appearsOnArtistId: widget.artist.id,
          ),
        );
    setState(() {
      _appearsOn = resp.items;
    });
  }

  Future<void> _getAlbums() async {
    final resp = await ref
        .read(mediaServerClientProvider)
        .getAlbums(
          LibraryQuery(
            sort: ItemSort.releaseDate,
            direction: SortDirection.descending,
            artistIds: [widget.artist.id],
          ),
        );
    setState(() {
      _albums = resp.items;
    });
  }

  Future<void> _onAlbumPlayPressed(LibraryItem album) => _playSet(
    album,
    () => ref.read(setPlaybackProvider.notifier).playAlbum(album),
  );

  Future<void> _onArtistPlayPressed() => _playSet(
    widget.artist,
    () => ref.read(setPlaybackProvider.notifier).playArtist(widget.artist),
  );

  Future<void> _playSet(
    LibraryItem setItem,
    Future<SetPlaybackResult> Function() play,
  ) async {
    try {
      final result = await play();
      if (result == SetPlaybackResult.empty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nothing to play in "${setItem.name}"')),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start playing "${setItem.name}"')),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.sizeOf(context);
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(_screenSize);
  }

  double get _horizontalPadding =>
      _device.isMobile ? 16 : (_device.isTablet ? 64 : 40);

  double get _headerHeight =>
      _device.isMobile ? 250 : (_device.isTablet ? 340 : 360);

  @override
  Widget build(BuildContext context) {
    return ScrollablePageScaffold(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          title: ValueListenableBuilder(
            valueListenable: _titleOpacity,
            builder: (context, opacity, child) => Transform.translate(
              offset: Offset(0, 8 - 8 * opacity),
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image(
                    image: ref
                        .read(imageServiceProvider)
                        .itemImage(
                          widget.artist,
                        ),
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          floating: true,
          pinned: true,
          expandedHeight: _headerHeight,
          backgroundColor: Colors.transparent,
          flexibleSpace: ValueListenableBuilder(
            valueListenable: _titleOpacity,
            builder: (context, opacity, child) => ClipRect(
              child: BackdropFilter(
                enabled: opacity > 0,
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: ColoredBox(
                  color: _theme.scaffoldBackgroundColor.withValues(
                    alpha: 0.8 * opacity,
                  ),
                  child: child,
                ),
              ),
            ),
            child: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  if (widget.artist.images.backdrops.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: _device.isMobile ? -60 : 0,
                      height: _device.isMobile ? 340 : _headerHeight,
                      child: _headerImage(),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: _device.isMobile ? 20 : _horizontalPadding,
                      top: 60,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _mainImage(),
                          ),
                        ),
                        Flexible(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _device.isMobile
                                  ? 16
                                  : _horizontalPadding,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        key: _titleKey,
                                        widget.artist.name,
                                        style: TextStyle(
                                          fontSize: _device.isMobile ? 18 : 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _playButton(),
                                  ],
                                ),
                                DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: _device.isMobile ? 14 : 16,
                                  ),
                                  child: _infoText(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ..._albumsWidgets(),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _headerImage() => Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: ref
            .read(imageServiceProvider)
            .itemImage(widget.artist, kind: ImageKind.backdrop),
        fit: BoxFit.fitWidth,
      ),
    ),
    foregroundDecoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _theme.scaffoldBackgroundColor.withOpacity(0),
          _theme.scaffoldBackgroundColor.withOpacity(1),
        ],
      ),
    ),
  );

  Widget _mainImage() => Image(
    image: ref.read(imageServiceProvider).itemImage(widget.artist),
    width: 500,
  );

  Widget _infoText() => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Text(
      _artist.overview ?? 'This artist does not have any information.',
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      style: _theme.textTheme.bodySmall?.copyWith(
        fontSize: 14,
        height: 1.2,
      ),
    ),
  );

  Widget _playButton() => SizedBox(
    height: 48,
    child: PlayButton(
      isLoading: ref.watch(setPlaybackProvider) == widget.artist.id,
      onPressed: _onArtistPlayPressed,
    ),
  );

  Widget _sectionHeading(String label) => SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.only(
        left: _device.isMobile ? 8 : _horizontalPadding,
        top: 8,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _device.isMobile ? 20 : 24,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  List<Widget> _albumsWidgets() {
    return [
      for (final section in releaseTypeSections(_albums)) ...[
        _sectionHeading(section.label),
        SliverPadding(
          padding: EdgeInsets.only(
            top: 16,
            right: _device.isMobile ? 16 : _horizontalPadding,
            left: _device.isMobile ? 16 : _horizontalPadding,
            bottom: 16,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _device.isMobile ? 200 : 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: _device.isMobile ? 8 : 16,
              childAspectRatio: _device.isMobile ? 175 / 225 : 120 / 163,
            ),
            itemBuilder: (context, index) => AlbumView(
              showArtist: false,
              album: section.albums[index],
              subtitle: section.albums[index].productionYear?.toString(),
              alignTextStart: true,
              optionsBuilder: (context) => contextMenuActions(
                context,
                ref,
                section.albums[index],
                scope: ContextMenuScope.browse,
                onLike: _onAlbumLikePressed,
              ),
              onTap: (album) => context.pushNamed(
                branchAwareName(context, Routes.album),
                extra: {
                  'album': album,
                  'artist': widget.artist,
                },
              ),
              onPlayPressed: _onAlbumPlayPressed,
              mainTextStyle: TextStyle(fontSize: _device.isMobile ? 16 : 14),
              subTextStyle: const TextStyle(fontSize: 14),
            ),
            itemCount: section.albums.length,
          ),
        ),
      ],
      if (_appearsOn.isNotEmpty) _sectionHeading('Appears On'),
      SliverPadding(
        padding: EdgeInsets.only(
          top: 16,
          right: _device.isMobile ? 16 : _horizontalPadding,
          left: _device.isMobile ? 16 : _horizontalPadding,
          bottom: 16,
        ),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: _device.isMobile ? 175 : 220,
            mainAxisSpacing: _device.isTablet ? 24 : 12,
            crossAxisSpacing: _device.isMobile ? 8 : 16,
            childAspectRatio: _device.isMobile ? 175 / 225 : 120 / 163,
          ),
          itemBuilder: (context, index) => AlbumView(
            showArtist: false,
            album: _appearsOn[index],
            subtitle: _appearsOn[index].productionYear?.toString(),
            alignTextStart: true,
            optionsBuilder: (context) => contextMenuActions(
              context,
              ref,
              _appearsOn[index],
              scope: ContextMenuScope.browse,
              onLike: _onAlbumLikePressed,
            ),
            onTap: (album) => context.pushNamed(
              branchAwareName(context, Routes.album),
              extra: {
                'album': album,
                'artist': widget.artist,
              },
            ),
            onPlayPressed: _onAlbumPlayPressed,
            mainTextStyle: TextStyle(fontSize: _device.isMobile ? 16 : 14),
            subTextStyle: const TextStyle(fontSize: 14),
          ),
          itemCount: _appearsOn.length,
        ),
      ),
      ..._missingAlbumsWidgets(),
      SliverToBoxAdapter(
        child: SimilarArtistsRow(
          artists: ref.watch(similarArtistsProvider(_catalogKey)),
          device: _device,
          horizontalPadding: _device.isMobile ? 16 : _horizontalPadding,
          showPlaceholder: _discoveryEnabled,
        ),
      ),
    ];
  }

  LibraryArtistKey get _catalogKey => (
    artistId: widget.artist.id,
    name: widget.artist.name,
  );

  bool get _discoveryEnabled => ref.watch(catalogSourcesProvider).isNotEmpty;

  EdgeInsets get _gridPadding => EdgeInsets.only(
    top: 16,
    right: _device.isMobile ? 16 : _horizontalPadding,
    left: _device.isMobile ? 16 : _horizontalPadding,
    bottom: 16,
  );

  SliverGridDelegate get _albumGridDelegate =>
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _device.isMobile ? 200 : 160,
        mainAxisSpacing: 12,
        crossAxisSpacing: _device.isMobile ? 8 : 16,
        childAspectRatio: _device.isMobile ? 175 / 225 : 120 / 163,
      );

  List<Widget> _missingAlbumsWidgets() {
    if (!_discoveryEnabled) return const [];
    final missing = ref.watch(missingAlbumsProvider(_catalogKey));
    if (missing.isLoading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: _device.isMobile ? 8 : _horizontalPadding,
              top: 8,
            ),
            child: SectionHeaderShimmer(
              width: 180,
              height: _device.isMobile ? 20 : 24,
            ),
          ),
        ),
        SliverPadding(
          padding: _gridPadding,
          sliver: AlbumCardsGridShimmer(
            device: _device,
            count: 4,
            gridDelegate: _albumGridDelegate,
          ),
        ),
      ];
    }
    final albums = missing.valueOrNull ?? const <CatalogAlbum>[];
    if (albums.isEmpty) return const [];
    return [
      _sectionHeading('Not in your library'),
      SliverPadding(
        padding: _gridPadding,
        sliver: SliverGrid.builder(
          gridDelegate: _albumGridDelegate,
          itemCount: albums.length,
          itemBuilder: (context, index) => CatalogAlbumCard(
            album: albums[index],
            muted: true,
            onTap: () => context.pushNamed(
              branchAwareName(context, Routes.catalogAlbum),
              extra: {'album': albums[index]},
            ),
          ),
        ),
      ),
    ];
  }
}
