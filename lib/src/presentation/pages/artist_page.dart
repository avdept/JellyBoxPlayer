import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/fanart_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

const _topSongsPreview = 5;
const double heroAspectRatio = 16 / 9;
const double mobileShadeStartFraction = 0.45;
const double maxShadeStartFraction = 0.6;
const int _shadeSteps = 12;
const _seeMoreHeight = 40.0;

class ArtistPage extends ConsumerStatefulWidget {
  const ArtistPage({required this.artist, super.key});
  final LibraryItem artist;

  @override
  ConsumerState<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends ConsumerState<ArtistPage> {
  final _scrollController = ScrollController();
  final GlobalKey _titleKey = GlobalKey(debugLabel: 'title');
  List<LibraryItem> _albums = [];
  List<LibraryItem> _appearsOn = [];
  List<LibraryItem> _topSongs = const [];
  var _showAllTopSongs = false;
  var _showFullBio = false;
  late LibraryItem _artist = widget.artist;

  late Size _screenSize;
  late ThemeData _theme;
  late DeviceType _device;

  @override
  void initState() {
    super.initState();
    _getAlbums();
    _getAppearsOn();
    _getTopSongs();
    _refreshArtist();
  }

  Future<void> _getTopSongs() async {
    final List<LibraryItem> songs;
    try {
      songs = await ref
          .read(mediaServerClientProvider)
          .getTopSongs(widget.artist);
    } on Object {
      return;
    }
    if (!mounted) return;
    setState(() => _topSongs = songs);
  }

  void _onTopSongUpdated(LibraryItem updated) {
    setState(() {
      _topSongs = [
        for (final song in _topSongs)
          if (song.id == updated.id) updated else song,
      ];
    });
  }

  void _onSeeMorePressed() =>
      setState(() => _showAllTopSongs = !_showAllTopSongs);

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

  double get _horizontalPadding => _device.isDesktop ? 40 : 16;

  double get _headerHeight =>
      _device.isMobile ? 250 : (_device.isTablet ? 400 : 440);

  double _shadeStart(double heroHeight) => _device.isMobile
      ? heroHeight * mobileShadeStartFraction
      : min(
          kToolbarHeight +
              ArtistHeaderBody.avatarTop +
              ArtistHeaderBody.avatarSize,
          heroHeight * maxShadeStartFraction,
        );

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: _tint ?? Colors.transparent),
      duration: const Duration(milliseconds: 600),
      builder: (context, tint, _) => _page(
        Color.alphaBlend(tint!, _theme.scaffoldBackgroundColor),
      ),
    );
  }

  Widget _page(Color base) {
    return ScrollablePageScaffold(
      controller: _scrollController,
      backgroundColor: base,
      background: _backdropUri == null
          ? null
          : LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxWidth / heroAspectRatio;
                return SizedBox(height: height, child: _hero(base, height));
              },
            ),
      slivers: [
        ArtistHeaderAppBar(
          barColor: base,
          controller: _scrollController,
          titleKey: _titleKey,
          name: widget.artist.name,
          titleImage: ref.read(imageServiceProvider).itemImage(widget.artist),
        ),
        ArtistHeaderBody(
          image: _mainImage(),
          headerHeight: _headerHeight,
          horizontalPadding: _horizontalPadding,
          isMobile: _device.isMobile,
          panel: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      key: _titleKey,
                      widget.artist.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _device.isMobile ? 22 : 44,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _playButton(),
                ],
              ),
              if (!_showFullBio)
                if (_artist.overview case final overview?)
                  _bioExcerpt(overview),
            ],
          ),
        ),
        if (_showFullBio)
          if (_artist.overview case final overview?) _fullBio(overview),
        if (_device.isMobile) ..._topSongsWidgets() else _popularAndNewest(),
        ..._albumsWidgets(),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Uri? get _backdropUri =>
      _fanartBackground ??
      ref
          .read(imageServiceProvider)
          .itemUri(widget.artist, kind: ImageKind.backdrop);

  Color? get _tint {
    if (!ref.watch(settingProvider(AppSetting.albumArtTint))) return null;
    final backdrop = _backdropUri;
    if (backdrop == null) return null;
    final color = ref.watch(artworkEdgeColorProvider(backdrop)).valueOrNull;
    if (color == null) return null;
    return Color.lerp(Colors.black, color, 0.5);
  }

  Uri? get _fanartBackground {
    if (!ref.watch(fanartArtistBackgroundsProvider)) return null;
    final id = fanartArtistId(_artist);
    if (id == null) return null;
    return ref
        .watch(fanartArtistImagesProvider(id))
        .valueOrNull
        ?.backgrounds
        .firstOrNull
        ?.uri;
  }

  Widget _hero(Color base, double height) {
    final images = ref.read(imageServiceProvider);
    final server = images.itemUri(widget.artist, kind: ImageKind.backdrop);
    final fanart = _fanartBackground;
    return Container(
      color: base,
      foregroundDecoration: BoxDecoration(gradient: _shade(base, height)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (server != null) _heroImage(images.artworkImage(server)),
          if (fanart != null)
            _heroImage(images.artworkImage(fanart), fadeIn: true),
        ],
      ),
    );
  }

  Widget _heroImage(ImageProvider image, {bool fadeIn = false}) => Image(
    image: image,
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
    frameBuilder: !fadeIn
        ? null
        : (context, child, frame, wasSynchronouslyLoaded) =>
              wasSynchronouslyLoaded
              ? child
              : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  child: child,
                ),
  );

  LinearGradient _shade(Color base, double height) {
    final start = _shadeStart(height) / height;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [
        0,
        for (var i = 0; i <= _shadeSteps; i++)
          start + (1 - start) * i / _shadeSteps,
      ],
      colors: [
        base.withValues(alpha: 0),
        for (var i = 0; i <= _shadeSteps; i++)
          base.withValues(
            alpha: Curves.easeOutCubic.transform(i / _shadeSteps),
          ),
      ],
    );
  }

  Widget _mainImage() => ClipOval(
    child: Image(
      image: ref.read(imageServiceProvider).itemImage(widget.artist),
      fit: BoxFit.cover,
    ),
  );

  static const _bioExcerptLines = 2;

  TextStyle? get _bioStyle =>
      _theme.textTheme.bodySmall?.copyWith(fontSize: 14, height: 1.3);

  Widget _bioExcerpt(String text) => LayoutBuilder(
    builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: _bioStyle),
        maxLines: _bioExcerptLines,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = painter.didExceedMaxLines;
      painter.dispose();

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              maxLines: _bioExcerptLines,
              overflow: TextOverflow.ellipsis,
              style: _bioStyle,
            ),
            if (overflows) _bioToggle('Read more'),
          ],
        ),
      );
    },
  );

  Widget _fullBio(String text) => SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.only(
        left: _device.isMobile ? 16 : _horizontalPadding,
        right: _device.isMobile ? 16 : _horizontalPadding,
        top: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(text, style: _bioStyle),
          _bioToggle('Read less'),
        ],
      ),
    ),
  );

  Widget _bioToggle(String label) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => _showFullBio = !_showFullBio),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style: _bioStyle?.copyWith(
          fontWeight: FontWeight.bold,
          color: _theme.colorScheme.onPrimary,
        ),
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

  Widget _popularAndNewest() => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
    sliver: SliverToBoxAdapter(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _topSongs.isEmpty
              ? const SizedBox(width: double.infinity)
              : Row(
                  key: const ValueKey('popular'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _popularColumn()),
                    if (_device.isDesktop) ...[
                      const SizedBox(width: 40),
                      Expanded(child: _newestColumn()),
                    ],
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _popularColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          label: 'Popular',
          fontSize: 24,
          padding: EdgeInsets.only(top: 8),
        ),
        SongListSliver(
          songs: _topSongs,
          limit: _showAllTopSongs ? null : _topSongsPreview,
          edgePadding: 0,
          showPosition: true,
          showCover: true,
          asColumn: true,
          onItemUpdated: _onTopSongUpdated,
        ),
        if (_topSongs.length > _topSongsPreview)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: HoverTextButton(
              label: _showAllTopSongs ? 'See less' : 'See more',
              onPressed: _onSeeMorePressed,
              fontSize: 15,
            ),
          ),
      ],
    );
  }

  Widget _newestColumn() {
    final card = _newestReleaseCard();
    if (card == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          label: 'Newest release',
          fontSize: 24,
          padding: EdgeInsets.only(top: 8),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: 160,
            height: 160 / _albumTileAspectRatio,
            child: card,
          ),
        ),
      ],
    );
  }

  Widget? _newestReleaseCard() {
    final owned = _albums.firstOrNull;
    final missing = _newestMissingAlbum;
    if (missing != null &&
        (owned?.productionYear == null ||
            missing.releaseDate!.year > owned!.productionYear!)) {
      return CatalogAlbumCard(
        album: missing,
        muted: true,
        subtitle: 'Not in your library',
        onTap: () => context.pushNamed(
          branchAwareName(context, Routes.catalogAlbum),
          extra: {'album': missing},
        ),
      );
    }
    return owned == null ? null : _albumCard(owned);
  }

  CatalogAlbum? get _newestMissingAlbum {
    if (!_discoveryEnabled) return null;
    final albums = ref.watch(missingAlbumsProvider(_catalogKey)).valueOrNull;
    return albums?.where((album) => album.releaseDate != null).firstOrNull;
  }

  List<Widget> _topSongsWidgets() {
    if (_topSongs.isEmpty) return const [];

    final canExpand = _topSongs.length > _topSongsPreview;
    final songs = SongListSliver(
      songs: _topSongs,
      limit: _showAllTopSongs ? null : _topSongsPreview,
      edgePadding: _device.isMobile ? 16 : _horizontalPadding,
      showPosition: true,
      showCover: true,
      asColumn: _device.isMobile,
      onItemUpdated: _onTopSongUpdated,
    );

    if (!_device.isMobile) {
      return [
        _sectionHeading('Popular'),
        songs,
        if (canExpand)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: _horizontalPadding, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: HoverTextButton(
                  label: _showAllTopSongs ? 'See less' : 'See more',
                  onPressed: _onSeeMorePressed,
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ];
    }

    return [
      _sectionHeading('Popular'),
      SliverToBoxAdapter(child: songs),
      if (canExpand) SliverToBoxAdapter(child: _seeMoreButton()),
    ];
  }

  Widget _seeMoreButton() => SizedBox(
    height: _seeMoreHeight,
    child: Center(
      child: HoverTextButton(
        label: _showAllTopSongs ? 'See less' : 'See more',
        onPressed: _onSeeMorePressed,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      ),
    ),
  );

  Widget _sectionHeading(String label) => SliverToBoxAdapter(
    child: SectionHeading(
      label: label,
      fontSize: _device.isMobile ? 20 : 24,
      padding: EdgeInsets.only(
        left: _device.isMobile ? 8 : _horizontalPadding,
        top: 8,
      ),
    ),
  );

  List<Widget> _albumsWidgets() {
    return [
      for (final section in releaseTypeSections(_albums)) ...[
        _sectionHeading(section.label),
        _albumGrid(section.albums),
      ],
      if (_appearsOn.isNotEmpty) _sectionHeading('Appears On'),
      _albumGrid(_appearsOn),
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

  Widget _albumGrid(List<LibraryItem> albums) => SliverPadding(
    padding: _gridPadding,
    sliver: SliverGrid.builder(
      gridDelegate: _albumGridDelegate,
      itemCount: albums.length,
      itemBuilder: (context, index) => _albumCard(albums[index]),
    ),
  );

  Widget _albumCard(LibraryItem album) => AlbumView(
    showArtist: false,
    album: album,
    subtitle: album.productionYear?.toString(),
    alignTextStart: true,
    optionsBuilder: (context) => contextMenuActions(
      context,
      ref,
      album,
      scope: ContextMenuScope.browse,
      onLike: _onAlbumLikePressed,
    ),
    onTap: (album) => context.pushNamed(
      branchAwareName(context, Routes.album),
      extra: {'album': album, 'artist': widget.artist},
    ),
    onPlayPressed: _onAlbumPlayPressed,
    mainTextStyle: TextStyle(fontSize: _device.isMobile ? 16 : 14),
    subTextStyle: const TextStyle(fontSize: 14),
  );

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
        childAspectRatio: _albumTileAspectRatio,
      );

  double get _albumTileAspectRatio => _device.isMobile ? 175 / 225 : 120 / 163;

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
