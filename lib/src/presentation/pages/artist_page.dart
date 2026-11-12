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

const _topSongsPreview = 5;
const _topSongsFadeHeight = 34.0;
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
      _device.isMobile ? 250 : (_device.isTablet ? 340 : 360);

  @override
  Widget build(BuildContext context) {
    return ScrollablePageScaffold(
      controller: _scrollController,
      slivers: [
        ArtistHeaderAppBar(
          controller: _scrollController,
          titleKey: _titleKey,
          name: widget.artist.name,
          titleImage: ref.read(imageServiceProvider).itemImage(widget.artist),
          image: _mainImage(),
          backdrop: widget.artist.images.backdrops.isNotEmpty
              ? _headerImage()
              : null,
          headerHeight: _headerHeight,
          horizontalPadding: _horizontalPadding,
          isMobile: _device.isMobile,
          panel: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                style: TextStyle(fontSize: _device.isMobile ? 14 : 16),
                child: _infoText(),
              ),
            ],
          ),
        ),
        ..._topSongsWidgets(),
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
      color: _theme.scaffoldBackgroundColor,
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

  Widget _mainImage() => ClipOval(
    child: Image(
      image: ref.read(imageServiceProvider).itemImage(widget.artist),
      fit: BoxFit.cover,
    ),
  );

  static const _bioLines = 5;

  Widget _infoText() {
    final text =
        _artist.overview ?? 'This artist does not have any information.';
    final style = _theme.textTheme.bodySmall?.copyWith(
      fontSize: 14,
      height: 1.2,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _bioLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: _bioLines,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: style,
              ),
              if (overflows)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showBio(text),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Read more',
                      style: style?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBio(String text) {
    final style = _theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.4,
    );
    if (!_device.isDesktop) {
      return showFormModal<void>(
        context,
        builder: (context) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalFormHeader(_artist.name),
              const SizedBox(height: 12),
              SelectableText(text, style: style),
            ],
          ),
        ),
      );
    }
    return showAppDialog<void>(
      context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 560,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModalFormHeader(_artist.name),
                const SizedBox(height: 12),
                Flexible(
                  child: Focus(
                    autofocus: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8),
                      child: SelectableText(text, style: style),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playButton() => SizedBox(
    height: 48,
    child: PlayButton(
      isLoading: ref.watch(setPlaybackProvider) == widget.artist.id,
      onPressed: _onArtistPlayPressed,
    ),
  );

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

    if (!canExpand) {
      return [_sectionHeading('Popular'), SliverToBoxAdapter(child: songs)];
    }

    return [
      _sectionHeading('Popular'),
      SliverToBoxAdapter(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: _seeMoreHeight / 2),
              child: songs,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _topSongsFadeHeight + _seeMoreHeight / 2,
              child: IgnorePointer(child: _topSongsFade()),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _seeMoreHeight,
              child: Center(child: _seeMoreButton()),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _topSongsFade() {
    const veilEnd =
        _topSongsFadeHeight / (_topSongsFadeHeight + _seeMoreHeight / 2);
    final background = _theme.scaffoldBackgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            background.withValues(alpha: 0),
            background.withValues(alpha: 0.12),
            background.withValues(alpha: 0.45),
            background.withValues(alpha: 0.85),
            background,
          ],
          stops: const [
            0,
            veilEnd * 0.3,
            veilEnd * 0.6,
            veilEnd * 0.85,
            veilEnd,
          ],
        ),
      ),
    );
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
      itemBuilder: (context, index) => AlbumView(
        showArtist: false,
        album: albums[index],
        subtitle: albums[index].productionYear?.toString(),
        alignTextStart: true,
        optionsBuilder: (context) => contextMenuActions(
          context,
          ref,
          albums[index],
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
      ),
    ),
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
