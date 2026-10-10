import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
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
import 'package:just_audio_background/just_audio_background.dart';

mixin AlbumPageState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  LibraryItem get album;
  AlbumPageKeys? get testKeys;
  double get edgePadding;
  double get navTitleFontSize;
  double get discHeaderFontSize;
  double get sectionTitleFontSize;
  double get titleInset => 0;
  Color? get playingRowColor => null;

  final GlobalKey titleKey = GlobalKey(debugLabel: 'title');
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<double> titleOpacity = ValueNotifier<double>(0);
  final ValueNotifier<MediaItem?> currentSong = ValueNotifier<MediaItem?>(
    null,
  );
  List<LibraryItem> songs = [];
  bool isLoadingSongs = true;
  bool loadFailed = false;
  bool _isDownloadBusy = false;
  late bool isFavorite;
  late final ImageService imageService;
  late ThemeData theme;
  late DeviceType device;

  ImageProvider get albumCover => imageService.itemImage(album);

  @override
  void initState() {
    super.initState();
    isFavorite = album.userData.isFavorite;
    imageService = ref.read(imageServiceProvider);
    unawaited(_loadSongs());
    currentSong.value = ref.read(nowPlayingProvider);
    ref.listenManual<MediaItem?>(nowPlayingProvider, (_, song) {
      if (!mounted) return;
      currentSong.value = song;
      ref.read(imageSchemeProvider.notifier).state = imageService.itemImage(
        album,
      );
    });
    scrollController.addListener(_onScroll);
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
    titleOpacity.dispose();
    currentSong.dispose();
    super.dispose();
  }

  void _onScroll() {
    final titleContext = titleKey.currentContext;
    if (!(titleContext?.mounted ?? false)) return;

    final scrollableContext =
        scrollController.position.context.notificationContext!;
    final scrollableRenderBox =
        scrollableContext.findRenderObject()! as RenderBox;
    final titleRenderBox = titleContext!.findRenderObject()! as RenderBox;
    final titlePosition = titleRenderBox.localToGlobal(
      Offset.zero,
      ancestor: scrollableRenderBox,
    );
    final titleHeight = titleContext.size!.height;
    final visibleFraction =
        (titlePosition.dy - titleInset + titleHeight) / titleHeight;

    titleOpacity.value = 1 - min(max(visibleFraction, 0), 1);
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

  List<LibraryItem> _sortedByIndex(List<LibraryItem> items) =>
      [...items]..sort(LibraryItem.compareAlbumOrder);

  Future<void> retryLoad() async {
    setState(() {
      isLoadingSongs = true;
      loadFailed = false;
    });
    await ref.read(connectivityProvider.notifier).refresh();
    if (mounted) await _getSongs(silent: false);
  }

  Widget navBar() => CupertinoNavigationBar(
    previousPageTitle: 'Albums',
    backgroundColor: Colors.transparent,
    enableBackgroundFilterBlur: false,
    padding: EdgeInsetsDirectional.symmetric(horizontal: edgePadding),
    middle: ValueListenableBuilder(
      valueListenable: titleOpacity,
      builder: (context, opacity, child) => Transform.translate(
        offset: Offset(0, 8 - 8 * opacity),
        child: Opacity(opacity: opacity, child: child),
      ),
      child: Text(
        album.name,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: navTitleFontSize,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    ),
  );

  List<Widget> contentSlivers() => [
    if (songs.isEmpty)
      SliverToBoxAdapter(child: _songsPlaceholder())
    else
      ..._songSlivers(),
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
            valueListenable: currentSong,
            builder: (context, item, other) {
              final song = section.songs[index];
              return SongRowView(
                song: song,
                isPlaying: item != null && song.id == item.id,
                onTap: (song) => ref
                    .read(playbackProvider.notifier)
                    .play(song, songs, album, sourceId: album.id),
                position: index + 1,
                showDownloadState: true,
                edgePadding: edgePadding,
                playingColor: playingRowColor,
                onLikePressed: onSongLikePressed,
                optionsBuilder: (context) => contextMenuActions(
                  context,
                  ref,
                  song,
                  scope: ContextMenuScope.albumPage,
                  onLike: onSongLikePressed,
                ),
              );
            },
          ),
          itemCount: section.songs.length,
        ),
      ],
    ];
  }

  Widget _discHeader(DiscSection section) => Padding(
    padding: EdgeInsets.fromLTRB(edgePadding, 20, edgePadding, 8),
    child: Text(
      section.discNumber != null ? 'Disc ${section.discNumber}' : 'Other',
      style: TextStyle(
        fontSize: discHeaderFontSize,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
      ),
    ),
  );

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
      onRetry: retryLoad,
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

  Widget albumDetails() {
    final durationInSeconds = album.duration.inSeconds;
    final hours = durationInSeconds ~/ Duration.secondsPerHour;
    final minutes =
        (durationInSeconds - hours * Duration.secondsPerHour) ~/
        Duration.secondsPerMinute;
    final seconds = durationInSeconds % Duration.secondsPerMinute;
    final year = album.productionYear;

    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.clock, size: 14),
          ),
          Text(
            [
              if (hours > 0) hours.toString().padLeft(2, '0'),
              minutes.toString().padLeft(2, '0'),
              seconds.toString().padLeft(2, '0'),
            ].join(':'),
          ),
          _detailsDot(),
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.music, size: 14),
          ),
          Text('${songs.length}'),
          if (year != null) ...[
            _detailsDot(),
            Text(
              year.toString(),
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsDot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Icon(
      Icons.circle,
      size: 4,
      color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
    ),
  );

  Widget playAlbumButton() => PlayButton(
    isLoading: ref.watch(setPlaybackProvider) == album.id,
    onPressed: onPlayAlbumPressed,
  );

  Future<void> onPlayAlbumPressed() async {
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
    onPressed: onLikeAlbumPressed,
    icon: Icon(CupertinoIcons.heart, color: theme.colorScheme.onPrimary),
    selectedIcon: Icon(
      CupertinoIcons.heart_fill,
      color: theme.colorScheme.primary,
    ),
    isSelected: isFavorite,
  );

  Future<void> onLikeAlbumPressed() async {
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
    } on Object {
      if (mounted) setState(() => isFavorite = !next);
      showOfflineSnackBar();
      return;
    }
    ref.invalidate(favouriteAlbumsProvider);
  }

  Widget downloadAlbumButton() => Consumer(
    builder: (context, ref, child) {
      final isDownloaded = ref
          .watch(isAlbumDownloadedProvider(album))
          .valueOrNull;
      if (isDownloaded == null) return const SizedBox.shrink();
      if (!isDownloaded && ref.watch(isOfflineProvider)) {
        return const SizedBox.shrink();
      }
      return IgnorePointer(
        ignoring: _isDownloadBusy,
        child: IconButton(
          key: isDownloaded ? testKeys?.deleteButton : testKeys?.downloadButton,
          onPressed: () => _onDownloadPressed(isDownloaded: isDownloaded),
          icon: Icon(isDownloaded ? JPlayer.trash_2 : JPlayer.download),
        ),
      );
    },
  );

  Future<void> _onDownloadPressed({required bool isDownloaded}) async {
    if (!isDownloaded && songs.isEmpty) {
      showOfflineSnackBar();
      return;
    }
    setState(() => _isDownloadBusy = true);
    if (!isDownloaded) {
      await ref
          .read(downloadManagerProvider.notifier)
          .downloadAlbum(album, songs);
    } else {
      final shouldDelete = await showAdaptiveDialog<bool>(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          key: testKeys?.confirmationDialog,
          title: Text.rich(
            TextSpan(
              text: 'Delete ',
              children: [
                TextSpan(
                  text: '"${album.name}"',
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
        await ref.read(downloadManagerProvider.notifier).deleteAlbum(album.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully deleted album')),
          );
        }
      }
    }
    _isDownloadBusy = false;
    if (mounted) setState(() {});
  }

  MoreFromArtistKey? get _moreFromArtistKey {
    final artist = album.albumArtists.firstOrNull;
    if (artist == null) return null;
    return (artistId: artist.id, albumId: album.id);
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
        child: Padding(
          padding: EdgeInsets.only(
            left: edgePadding,
            right: edgePadding,
            top: 24,
            bottom: 12,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: sectionTitleFontSize,
              fontWeight: FontWeight.w500,
            ),
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

  Future<void> onSongLikePressed(LibraryItem song) async {
    if (ref.read(isOfflineProvider)) {
      showOfflineSnackBar();
      return;
    }
    try {
      await ref
          .read(mediaServerClientProvider)
          .setFavorite(song.id, favorite: !song.userData.isFavorite);
    } on Object {
      showOfflineSnackBar();
      return;
    }
    ref.invalidate(favouriteSongsProvider);
    unawaited(_getSongs());
  }
}
