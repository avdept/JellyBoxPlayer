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
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

@visibleForTesting
class AlbumPageKeys {
  @visibleForTesting
  const AlbumPageKeys({
    required this.downloadButton,
    required this.deleteButton,
    required this.confirmationDialog,
  });

  final Key downloadButton;
  final Key deleteButton;
  final Key confirmationDialog;
}

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({
    required this.album,
    @visibleForTesting this.testKeys,
    super.key,
  });
  final LibraryItem album;
  final AlbumPageKeys? testKeys;

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final _titleKey = GlobalKey(debugLabel: 'title');
  final _scrollController = ScrollController();
  final _titleOpacity = ValueNotifier<double>(0);
  final _currentSong = ValueNotifier<MediaItem?>(null);
  List<LibraryItem> songs = [];
  var _isLoading = false;
  var _isLoadingSongs = true;
  var _loadFailed = false;
  late bool _isFavorite;

  late final ImageService _imageService;

  late ThemeData _theme;
  late DeviceType _device;

  Future<void> _onAddToPlaylistPressed(LibraryItem song) async {
    if (ref.read(isOfflineProvider)) {
      _showOfflineSnackBar();
      return;
    }
    final playlist = await showPlaylistPicker(
      context,
      isDesktop: _device.isDesktop,
    );
    if (playlist != null) {
      await ref
          .read(mediaServerClientProvider)
          .addPlaylistItems(playlistId: playlist.id, itemIds: [song.id]);
      unawaited(_getSongs());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully added item to playlist')),
        );
      }
    }
  }

  void _showOfflineSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not available offline')),
    );
  }

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
    _isFavorite = widget.album.userData.isFavorite;
    _imageService = ref.read(imageServiceProvider);
    unawaited(_loadSongs());
    _currentSong.value = ref.read(nowPlayingProvider);
    ref.listenManual<MediaItem?>(nowPlayingProvider, (_, song) {
      if (!mounted) return;
      _currentSong.value = song;
      ref.read(imageSchemeProvider.notifier).state = _imageService.itemImage(
        widget.album,
      );
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadSongs() async {
    var downloaded = const <DownloadedSong>[];
    try {
      downloaded = await ref
          .read(downloadDatabaseProvider)
          .getDownloadedSongs(widget.album.id);
    } on Object catch (error) {
      debugPrint('[AlbumPage] could not read downloaded songs: $error');
    }
    if (!mounted) return;

    if (downloaded.isNotEmpty) {
      setState(() {
        songs = _sortedByIndex(
          downloaded.map((s) => s.item).toList(),
        );
        _isLoadingSongs = false;
      });
    }

    await _getSongs(silent: downloaded.isNotEmpty);
  }

  Future<void> _getSongs({bool silent = true}) async {
    if (ref.read(isOfflineProvider)) {
      if (mounted) {
        setState(() {
          _isLoadingSongs = false;
          if (!silent) _loadFailed = true;
        });
      }
      return;
    }

    try {
      final response = await ref
          .read(mediaServerClientProvider)
          .getSongs(
            userId: ref.read(currentUserProvider)!.userId,
            albumId: widget.album.id,
          );
      if (!mounted) return;
      setState(() {
        songs = _sortedByIndex(response.items);
        _isLoadingSongs = false;
        _loadFailed = false;
      });
    } on Object catch (error) {
      debugPrint('[AlbumPage] could not load songs: $error');
      unawaited(ref.read(connectivityProvider.notifier).refresh());
      if (!mounted) return;
      setState(() {
        _isLoadingSongs = false;
        if (!silent) _loadFailed = true;
      });
    }
  }

  List<LibraryItem> _sortedByIndex(List<LibraryItem> items) =>
      [...items]..sort((a, b) => a.indexNumber.compareTo(b.indexNumber));

  Future<void> _retryLoad() async {
    setState(() {
      _isLoadingSongs = true;
      _loadFailed = false;
    });
    await ref.read(connectivityProvider.notifier).refresh();
    if (mounted) await _getSongs(silent: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  ImageProvider get albumCover => _imageService.itemImage(widget.album);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoNavigationBar(
                previousPageTitle: 'Albums',
                backgroundColor: Colors.transparent,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: _device.isMobile ? 16 : 30,
                ),
                middle: ValueListenableBuilder(
                  valueListenable: _titleOpacity,
                  builder: (context, opacity, child) => Transform.translate(
                    offset: Offset(0, 8 - 8 * opacity),
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  ),
                  child: Text(
                    widget.album.name,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: _device.isMobile ? 14 : 20,
                      color: _theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollbar(
                  controller: _scrollController,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      if (_device.isDesktop)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Image(
                                  image: albumCover,
                                  height: 254,
                                ),
                                const SizedBox(width: 38),
                                Expanded(child: _albumPanel()),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _device.isMobile ? 16 : 30,
                          ),
                          sliver: SliverPersistentHeader(
                            pinned: true,
                            delegate: _FadeOutImageDelegate(
                              image: albumCover,
                              isMobile: _device.isMobile,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: _device.isMobile ? 16 : 30,
                            top: _device.isMobile ? 15 : 35,
                            right: _device.isMobile ? 16 : 30,
                            bottom: _device.isMobile ? 0 : 18,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _albumPanelMobile(),
                          ),
                        ),
                      ],
                      if (songs.isEmpty)
                        SliverToBoxAdapter(child: _songsPlaceholder())
                      else
                        SliverList.builder(
                          itemBuilder: (context, index) =>
                              ValueListenableBuilder(
                                valueListenable: _currentSong,
                                builder: (context, item, other) {
                                  final song = songs[index];
                                  return SongRowView(
                                    song: song,
                                    isPlaying:
                                        item != null && song.id == item.id,
                                    onTap: (song) => ref
                                        .read(playbackProvider.notifier)
                                        .play(song, songs, widget.album),
                                    position: index + 1,
                                    showDownloadState: true,
                                    edgePadding: _device.isMobile ? 16 : 30,
                                    onLikePressed: _onSongLikePressed,
                                    optionsBuilder: (context) => [
                                      PopupMenuItem(
                                        onTap: () =>
                                            _onAddToPlaylistPressed(song),
                                        child: const Text('Add to playlist'),
                                      ),
                                      if (!_device.isDesktop)
                                        PopupMenuItem(
                                          onTap: () => _onSongLikePressed(song),
                                          child: Text(
                                            favouriteMenuLabel(song),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                          itemCount: songs.length,
                        ),
                      ..._suggestedAlbumsSlivers(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _titleOpacity.dispose();
    _currentSong.dispose();
  }

  Widget _albumPanelMobile() => IconTheme.merge(
    data: IconThemeData(size: _device.isMobile ? 24 : 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.album.name,
                key: _titleKey,
                style: TextStyle(
                  fontSize: _device.isMobile ? 18 : 32,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        Text(widget.album.albumArtist ?? ''),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _albumDetails(
              duration: widget.album.duration,
              soundsCount: songs.length,
              year: widget.album.productionYear,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _downloadAlbumButton(),
                _likeAlbumButton(),
                const RandomQueueButton(),
                SizedBox.square(
                  dimension: _device.isMobile ? 38 : 48,
                  child: _playAlbumButton(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  Widget _albumPanel() => IconTheme.merge(
    data: const IconThemeData(size: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.album.name,
                      key: _titleKey,
                      style: TextStyle(
                        fontSize: _device.isMobile ? 18 : 32,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              // Text(widget.album.albumArtist ?? ''),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: widget.album.albumArtists.map((a) {
                    return ClickableWidget(
                      onPressed: () async {
                        final item = await ref
                            .read(mediaServerClientProvider)
                            .getItem(a.id);
                        if (!mounted) return;
                        await context.pushNamed(
                          branchAwareName(context, Routes.artist),
                          extra: {'artist': item},
                        );
                      },
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                      ),
                      child: Text(a.name),
                    );
                  }).toList(),
                ),
              ),
              Row(
                children: [
                  _albumDetails(
                    duration: widget.album.duration,
                    soundsCount: songs.length,
                    year: widget.album.productionYear,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: _device.isDesktop ? 35 : 32),
        if (_device.isDesktop)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _downloadAlbumButton(),
              _likeAlbumButton(),
            ],
          )
        // StreamBuilder<PlayerState>(
        //   stream: ref.read(playerProvider).playerStateStream,
        //   builder: (context, snapshot) {
        //     return Expanded(
        //       child: Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           SizedBox.square(
        //             dimension: 65,
        //             child: _playAlbumButton(),
        //           ),
        //           _downloadAlbumButton(),
        //         ],
        //       ),
        //     );
        //   },
        // )
        else
          Wrap(
            spacing: _device.isMobile ? 6 : 32,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _downloadAlbumButton(),
              _likeAlbumButton(),
              const RandomQueueButton(),
              SizedBox.square(
                dimension: _device.isMobile ? 40 : 48,
                child: _playAlbumButton(),
              ),
            ],
          ),
      ],
    ),
  );

  Widget _playAlbumButton() => PlayButton(
    isLoading: ref.watch(setPlaybackProvider) == widget.album.id,
    onPressed: _onPlayAlbumPressed,
  );

  Future<void> _onPlayAlbumPressed() async {
    try {
      final result = await ref
          .read(setPlaybackProvider.notifier)
          .playAlbum(widget.album);
      if (result == SetPlaybackResult.empty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nothing to play in "${widget.album.name}"'),
          ),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start playing "${widget.album.name}"'),
          ),
        );
      }
    }
  }

  List<Widget> _suggestedAlbumsSlivers() {
    final albums = ref
        .watch(similarAlbumsProvider(widget.album.id))
        .valueOrNull;
    if (albums == null || albums.isEmpty) return const [];

    final horizontalPadding = _device.isMobile ? 16.0 : 30.0;
    final cardWidth = AlbumCardMetrics.width(_device);
    final cardHeight = AlbumCardMetrics.height(
      cardWidth,
      isTablet: _device.isTablet,
    );

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 24,
            bottom: 12,
          ),
          child: Text(
            'You may also like',
            style: TextStyle(
              fontSize: _device.isMobile ? 20 : 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: 16,
            ),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: AlbumView(
                album: albums[index],
                onTap: (album) => context.pushNamed(
                  branchAwareName(context, Routes.album),
                  extra: {'album': album},
                ),
                onPlayPressed: (album) =>
                    ref.read(setPlaybackProvider.notifier).playAlbum(album),
              ),
            ),
            separatorBuilder: (context, index) =>
                SizedBox(width: AlbumCardMetrics.crossAxisSpacing(_device)),
            itemCount: albums.length,
          ),
        ),
      ),
    ];
  }

  Widget _songsPlaceholder() {
    if (_isLoadingSongs) {
      return SongRowsShimmer(
        device: _device,
        count: 6,
        edgePadding: _device.isMobile ? 16 : 30,
      );
    }

    if (!_loadFailed && !ref.watch(isOfflineProvider)) {
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

  Future<void> _onSongLikePressed(LibraryItem song) async {
    if (ref.read(isOfflineProvider)) {
      _showOfflineSnackBar();
      return;
    }
    try {
      await ref
          .read(mediaServerClientProvider)
          .setFavorite(song.id, favorite: !song.userData.isFavorite);
    } on Object {
      _showOfflineSnackBar();
      return;
    }
    ref.invalidate(favouriteSongsProvider);
    unawaited(_getSongs());
  }

  Future<void> _onLikeAlbumPressed() async {
    if (ref.read(isOfflineProvider)) {
      _showOfflineSnackBar();
      return;
    }
    final next = !_isFavorite;
    setState(() => _isFavorite = next);
    try {
      await ref
          .read(mediaServerClientProvider)
          .setFavorite(widget.album.id, favorite: next);
    } on Object {
      if (mounted) setState(() => _isFavorite = !next);
      _showOfflineSnackBar();
      return;
    }
    ref.invalidate(favouriteAlbumsProvider);
  }

  Widget _likeAlbumButton() => IconButton(
    onPressed: _onLikeAlbumPressed,
    icon: Icon(
      CupertinoIcons.heart,
      color: _theme.colorScheme.onPrimary,
    ),
    selectedIcon: Icon(
      CupertinoIcons.heart_fill,
      color: _theme.colorScheme.primary,
    ),
    isSelected: _isFavorite,
  );

  Widget _downloadAlbumButton() => Consumer(
    builder: (context, ref, child) {
      final isDownloaded = ref
          .watch(isAlbumDownloadedProvider(widget.album))
          .valueOrNull;
      if (isDownloaded == null) return const SizedBox.shrink();
      if (!isDownloaded && ref.watch(isOfflineProvider)) {
        return const SizedBox.shrink();
      }
      return IgnorePointer(
        ignoring: _isLoading,
        child: IconButton(
          key: isDownloaded
              ? widget.testKeys?.deleteButton
              : widget.testKeys?.downloadButton,
          onPressed: () async {
            if (!isDownloaded && songs.isEmpty) {
              _showOfflineSnackBar();
              return;
            }
            setState(() => _isLoading = true);
            if (!isDownloaded) {
              await ref
                  .read(downloadManagerProvider.notifier)
                  .downloadAlbum(widget.album, songs);
            } else {
              final shouldDelete = await showAdaptiveDialog<bool>(
                context: context,
                builder: (context) => AlertDialog.adaptive(
                  key: widget.testKeys?.confirmationDialog,
                  title: Text.rich(
                    TextSpan(
                      text: 'Delete ',
                      children: [
                        TextSpan(
                          text: '"${widget.album.name}"',
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
                    .read(downloadManagerProvider.notifier)
                    .deleteAlbum(widget.album.id);
                if (context.mounted) {
                  const snackBar = SnackBar(
                    content: Text('Successfully deleted album'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              }
            }
            _isLoading = false;
            if (mounted) setState(() {});
          },
          icon: Icon(isDownloaded ? JPlayer.trash_2 : JPlayer.download),
        ),
      );
    },
  );

  Widget _detailsDot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Icon(
      Icons.circle,
      size: 4,
      color: _theme.colorScheme.onPrimary.withValues(alpha: 0.6),
    ),
  );

  Widget _albumDetails({
    required Duration duration,
    required int soundsCount,
    int? year,
  }) {
    final durationInSeconds = duration.inSeconds;
    final hours = durationInSeconds ~/ Duration.secondsPerHour;
    final minutes =
        (durationInSeconds - hours * Duration.secondsPerHour) ~/
        Duration.secondsPerMinute;
    final seconds = durationInSeconds % Duration.secondsPerMinute;

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
          Text('$soundsCount'),
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
}

class _FadeOutImageDelegate extends SliverPersistentHeaderDelegate {
  const _FadeOutImageDelegate({
    required this.image,
    required this.isMobile,
  });

  final ImageProvider image;
  final bool isMobile;

  @override
  double get maxExtent => isMobile ? 182 : 299;

  @override
  double get minExtent => 0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Image(
      image: image,
      height: max(maxExtent - shrinkOffset, 0),
      opacity: AlwaysStoppedAnimation(
        max((maxExtent - shrinkOffset * 1.5) / maxExtent, 0),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FadeOutImageDelegate oldDelegate) =>
      image != oldDelegate.image || isMobile != oldDelegate.isMobile;
}
