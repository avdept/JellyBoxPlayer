import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/album/album_page.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

mixin AlbumPageState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  LibraryItem get album;
  AlbumPageKeys? get testKeys;
  double get edgePadding;
  double get navTitleFontSize;
  double get discHeaderFontSize;
  double get sectionTitleFontSize;
  Color? get playingRowColor => null;

  final GlobalKey titleKey = GlobalKey(debugLabel: 'title');
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<String?> playingSongId = ValueNotifier<String?>(null);
  List<LibraryItem> songs = [];
  bool isLoadingSongs = true;
  bool loadFailed = false;
  String? description;
  bool descriptionExpanded = false;
  late bool isFavorite;
  late final ImageService imageService;
  late ThemeData theme;
  late DeviceType device;

  ImageProvider get albumCover => imageService.itemImage(album);

  @override
  void initState() {
    super.initState();
    isFavorite = album.userData.isFavorite;
    description = album.overview;
    imageService = ref.read(imageServiceProvider);
    unawaited(_loadSongs());
    unawaited(_loadDescription());
    playingSongId.value = ref.read(barSongProvider)?.id;
    ref.listenManual<String?>(barSongProvider.select((song) => song?.id), (
      _,
      songId,
    ) {
      if (!mounted) return;
      playingSongId.value = songId;
      ref.read(imageSchemeProvider.notifier).state = imageService.itemImage(
        album,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  void dispose() {
    scrollController.dispose();
    playingSongId.dispose();
    super.dispose();
  }

  void showOfflineSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not available offline')),
    );
  }

  Future<void> _loadSongs() async {
    var downloaded = const <DownloadedSong>[];
    try {
      downloaded = await ref
          .read(downloadDatabaseProvider)
          .getDownloadedSongs(album.id);
    } on Object catch (error) {
      debugPrint('[AlbumPage] could not read downloaded songs: $error');
    }
    if (!mounted) return;

    if (downloaded.isNotEmpty) {
      setState(() {
        songs = _sortedByIndex(downloaded.map((s) => s.item).toList());
        isLoadingSongs = false;
      });
    }

    await _getSongs(silent: downloaded.isNotEmpty);
  }

  Future<void> _getSongs({bool silent = true}) async {
    if (ref.read(isOfflineProvider)) {
      if (mounted) {
        setState(() {
          isLoadingSongs = false;
          if (!silent) loadFailed = true;
        });
      }
      return;
    }

    try {
      final response = await ref
          .read(mediaServerClientProvider)
          .getSongs(album.id);
      if (!mounted) return;
      setState(() {
        songs = _sortedByIndex(response.items);
        isLoadingSongs = false;
        loadFailed = false;
      });
    } on Object catch (error) {
      debugPrint('[AlbumPage] could not load songs: $error');
      unawaited(ref.read(connectivityProvider.notifier).refresh());
      if (!mounted) return;
      setState(() {
        isLoadingSongs = false;
        if (!silent) loadFailed = true;
      });
    }
  }

  Future<void> _loadDescription() async {
    if (ref.read(isOfflineProvider)) return;
    final LibraryItem fresh;
    try {
      fresh = await ref
          .read(mediaServerClientProvider)
          .getItem(album.id, kind: ItemKind.album);
    } on Object {
      return;
    }
    final text = fresh.overview?.trim();
    if (!mounted || text == null || text.isEmpty) return;
    setState(() => description = text);
  }

  List<LibraryItem> _sortedByIndex(List<LibraryItem> items) =>
      [...items]..sort(LibraryItem.compareAlbumOrder);

  Future<void> _retryLoad() async {
    setState(() {
      isLoadingSongs = true;
      loadFailed = false;
    });
    await ref.read(connectivityProvider.notifier).refresh();
    if (mounted) await _getSongs(silent: false);
  }

  List<Widget> contentSlivers() => [
    if (songs.isEmpty)
      SliverToBoxAdapter(child: _songsPlaceholder())
    else
      ..._songSlivers(),
    ..._descriptionSlivers(),
    ..._moreFromArtistSlivers(),
    ..._suggestedAlbumsSlivers(),
  ];

  List<Widget> _songSlivers() {
    final sections = discSections(songs);
    final showHeaders = sections.length > 1;
    return [
      for (final section in sections) ...[
        if (showHeaders) SliverToBoxAdapter(child: _discHeader(section)),
        SliverList.builder(
          itemBuilder: (context, index) => ValueListenableBuilder(
            valueListenable: playingSongId,
            builder: (context, songId, other) {
              final song = section.songs[index];
              return SongRowView(
                song: song,
                isPlaying: song.id == songId,
                onTap: (song) => ref
                    .read(playbackProvider.notifier)
                    .play(song, songs, album, sourceId: album.id),
                position: index + 1,
                edgePadding: edgePadding,
                playingColor: playingRowColor,
                onLikePressed: _onSongLikePressed,
                onRatingChanged: _onSongRated,
                optionsBuilder: (context) => contextMenuActions(
                  context,
                  ref,
                  song,
                  scope: ContextMenuScope.albumPage,
                  onLike: _onSongLikePressed,
                ),
              );
            },
          ),
          itemCount: section.songs.length,
        ),
      ],
    ];
  }

  Widget _discHeader(DiscSection section) {
    final coverArt = section.coverArt;
    final headerColor = theme.colorScheme.onPrimary.withValues(alpha: 0.8);
    return DiscHeader(
      title:
          section.title ??
          (section.discNumber != null ? 'Disc ${section.discNumber}' : 'Other'),
      fontSize: discHeaderFontSize,
      edgePadding: edgePadding,
      leading: coverArt != null && coverArt != album.images.primary
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image(
                image: _discCoverImage(coverArt),
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            )
          : null,
      trailing: HoverIconButton(
        icon: const Icon(Icons.play_arrow_outlined),
        tooltip: 'Play disc',
        color: headerColor,
        onPressed: () => _playDisc(section),
      ),
    );
  }

  ImageProvider _discCoverImage(String coverArt) => imageService.itemImage(
    LibraryItem(
      id: coverArt,
      name: '',
      kind: ItemKind.album,
      images: ImageRefs(primary: coverArt),
    ),
    size: 64,
  );

  Future<void> _playDisc(DiscSection section) async {
    final first = section.songs.firstOrNull;
    if (first == null) return;
    await ref
        .read(playbackProvider.notifier)
        .play(first, section.songs, album, sourceId: album.id);
  }

  Widget _songsPlaceholder() {
    if (isLoadingSongs) {
      return SongRowsShimmer(
        device: device,
        count: 6,
        edgePadding: edgePadding,
      );
    }

    if (!loadFailed && !ref.watch(isOfflineProvider)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('No songs in this album')),
      );
    }

    return OfflineNotice(
      message: ref.watch(isOfflineProvider)
          ? "You're offline and this album isn't downloaded."
          : 'Could not load this album.',
      onRetry: _retryLoad,
    );
  }

  Widget albumArtists(TextStyle style) {
    final artists = album.albumArtists;
    if (artists.isEmpty) {
      return Text(album.albumArtist ?? '', style: style);
    }
    return Wrap(
      children: artists.map((a) {
        return ClickableWidget(
          onPressed: () async {
            final item = await ref
                .read(mediaServerClientProvider)
                .getItem(a.id, kind: ItemKind.artist);
            if (!mounted) return;
            await context.pushNamed(
              branchAwareName(context, Routes.artist),
              extra: {'artist': item},
            );
          },
          textStyle: style,
          child: Text(a.name),
        );
      }).toList(),
    );
  }

  Widget albumDetails() => AlbumDetailsRow(
    duration: album.duration,
    songCount: songs.length,
    year: album.productionYear,
  );

  Widget playAlbumButton() => PlayButton(
    isLoading: ref.watch(setPlaybackProvider) == album.id,
    onPressed: _onPlayAlbumPressed,
  );

  Future<void> _onPlayAlbumPressed() async {
    try {
      final result = await ref
          .read(setPlaybackProvider.notifier)
          .playAlbum(album);
      if (result == SetPlaybackResult.empty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nothing to play in "${album.name}"')),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start playing "${album.name}"')),
        );
      }
    }
  }

  Widget likeAlbumButton() => IconButton(
    onPressed: _onLikeAlbumPressed,
    icon: Icon(CupertinoIcons.heart, color: theme.colorScheme.onPrimary),
    selectedIcon: Icon(
      CupertinoIcons.heart_fill,
      color: theme.colorScheme.primary,
    ),
    isSelected: isFavorite,
  );

  Future<void> _onLikeAlbumPressed() async {
    if (ref.read(isOfflineProvider)) {
      showOfflineSnackBar();
      return;
    }
    final next = !isFavorite;
    setState(() => isFavorite = next);
    try {
      await ref
          .read(mediaServerClientProvider)
          .setFavorite(album.id, favorite: next);
      ref.read(favouritesChangedProvider.notifier).state++;
    } on Object {
      if (mounted) setState(() => isFavorite = !next);
      showOfflineSnackBar();
      return;
    }
    ref.invalidate(favouriteAlbumsProvider);
  }

  Widget downloadAlbumButton() => CollectionDownloadButton(
    item: album,
    songs: () async => songs,
    testKeys: switch (testKeys) {
      final keys? => CollectionDownloadButtonKeys(
        download: keys.downloadButton,
        delete: keys.deleteButton,
        confirmationDialog: keys.confirmationDialog,
      ),
      null => null,
    },
  );

  MoreFromArtistKey? get _moreFromArtistKey {
    final artist = album.albumArtists.firstOrNull;
    if (artist == null) return null;
    return (artistId: artist.id, albumId: album.id);
  }

  List<Widget> _descriptionSlivers() {
    final text = description?.trim();
    if (text == null || text.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: SectionHeading(
          label: 'About',
          fontSize: sectionTitleFontSize,
          padding: EdgeInsets.only(
            left: edgePadding,
            right: edgePadding,
            top: 24,
            bottom: 12,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: edgePadding),
          child: _descriptionText(text),
        ),
      ),
    ];
  }

  Widget _descriptionText(String text) {
    final style = TextStyle(
      fontSize: 14,
      height: 1.4,
      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
    );
    const collapsedLines = 4;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Text(
                text,
                maxLines: descriptionExpanded ? null : collapsedLines,
                overflow: descriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (overflows)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => descriptionExpanded = !descriptionExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    descriptionExpanded ? 'Show less' : 'Read more',
                    style: style.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _moreFromArtistSlivers() {
    final key = _moreFromArtistKey;
    if (key == null) return const [];
    final albums = ref.watch(moreFromArtistProvider(key)).valueOrNull;
    if (albums == null || albums.isEmpty) return const [];
    return _albumRowSlivers(
      title: 'More from ${album.albumArtists.first.name}',
      albums: albums,
      onLike: _onMoreFromArtistLikePressed,
    );
  }

  List<Widget> _suggestedAlbumsSlivers() {
    final albums = ref.watch(similarAlbumsProvider(album.id)).valueOrNull;
    if (albums == null || albums.isEmpty) return const [];
    return _albumRowSlivers(
      title: 'You may also like',
      albums: albums,
      onLike: _onSuggestedAlbumLikePressed,
    );
  }

  List<Widget> _albumRowSlivers({
    required String title,
    required List<LibraryItem> albums,
    required Future<void> Function(LibraryItem) onLike,
  }) {
    final cardWidth = AlbumCardMetrics.width(device);
    final cardHeight = AlbumCardMetrics.height(
      cardWidth,
      isTablet: device.isTablet,
    );

    return [
      SliverToBoxAdapter(
        child: SectionHeading(
          label: title,
          fontSize: sectionTitleFontSize,
          padding: EdgeInsets.only(
            left: edgePadding,
            right: edgePadding,
            top: 24,
            bottom: 12,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: cardHeight,
          child: HorizontalScrollRegion(
            controlsHeight: cardWidth,
            controlsInset: edgePadding / 2,
            builder: (context, controller) => ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                left: edgePadding,
                right: edgePadding,
                bottom: 16,
              ),
              itemBuilder: (context, index) => SizedBox(
                width: cardWidth,
                child: AlbumView(
                  album: albums[index],
                  optionsBuilder: (context) => contextMenuActions(
                    context,
                    ref,
                    albums[index],
                    scope: ContextMenuScope.browse,
                    onLike: onLike,
                  ),
                  onTap: (album) => context.pushNamed(
                    branchAwareName(context, Routes.album),
                    extra: {'album': album},
                  ),
                  onPlayPressed: (album) =>
                      ref.read(setPlaybackProvider.notifier).playAlbum(album),
                ),
              ),
              separatorBuilder: (context, index) =>
                  SizedBox(width: AlbumCardMetrics.crossAxisSpacing(device)),
              itemCount: albums.length,
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _onSuggestedAlbumLikePressed(LibraryItem album) async {
    await toggleFavourite(ref, album);
    ref.invalidate(similarAlbumsProvider(this.album.id));
  }

  Future<void> _onMoreFromArtistLikePressed(LibraryItem album) async {
    await toggleFavourite(ref, album);
    final key = _moreFromArtistKey;
    if (key != null) ref.invalidate(moreFromArtistProvider(key));
  }

  Future<void> _onSongLikePressed(LibraryItem song) async {
    if (ref.read(isOfflineProvider)) {
      showOfflineSnackBar();
      return;
    }
    try {
      await ref
          .read(mediaServerClientProvider)
          .setFavorite(song.id, favorite: !song.userData.isFavorite);
      ref.read(favouritesChangedProvider.notifier).state++;
    } on Object {
      showOfflineSnackBar();
      return;
    }
    ref.invalidate(favouriteSongsProvider);
    unawaited(_getSongs());
  }

  Future<void> _onSongRated(LibraryItem song, int rating) async {
    if (ref.read(isOfflineProvider)) {
      showOfflineSnackBar();
      return;
    }
    try {
      await rateItem(ref, song, rating);
    } on Object {
      showOfflineSnackBar();
      return;
    }
    unawaited(_getSongs());
  }
}
