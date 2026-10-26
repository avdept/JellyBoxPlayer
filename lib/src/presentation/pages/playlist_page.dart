import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/download_sync_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/domain/providers/playlist_song_order_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class PlaylistPage extends ConsumerStatefulWidget {
  const PlaylistPage({required this.playlist, super.key});
  final LibraryItem playlist;

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  final _scrollController = ScrollController();
  final _titleOpacity = ValueNotifier<double>(0);
  late ValueNotifier<String?> _playingSongId;
  final _titleKey = GlobalKey(debugLabel: 'title');
  List<LibraryItem> songs = [];
  bool _songsLoaded = false;

  late final ImageService _imageService;

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
    _playingSongId = ValueNotifier<String?>(null);
    _imageService = ref.read(imageServiceProvider);
    unawaited(_getSongs());
    _playingSongId.value = ref.read(barSongProvider)?.id;
    ref.listenManual<String?>(barSongProvider.select((song) => song?.id), (
      _,
      songId,
    ) {
      if (!mounted) return;
      _playingSongId.value = songId;
      ref.read(imageSchemeProvider.notifier).state = _imageService.itemImage(
        widget.playlist,
      );
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _getSongs() async {
    if (ref.read(isOfflineProvider)) {
      await _getDownloadedSongs();
      return;
    }
    try {
      final value = await ref
          .read(mediaServerClientProvider)
          .getPlaylistSongs(widget.playlist.id);
      if (!mounted) return;
      setState(() {
        songs = [...value.items]
          ..sort((a, b) => a.indexNumber.compareTo(b.indexNumber));
        _songsLoaded = true;
      });
    } on Object {
      await _getDownloadedSongs();
    }
  }

  Future<void> _getDownloadedSongs() async {
    final downloaded = await ref
        .read(downloadDatabaseProvider)
        .getDownloadedPlaylistSongs(widget.playlist.id);
    if (!mounted) return;
    setState(() {
      songs = downloaded.map((s) => s.item).toList();
      _songsLoaded = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  ImageProvider get albumCover => _imageService.itemImage(widget.playlist);

  PlaylistSongOrder get _order =>
      ref.watch(playlistSongOrderProvider(widget.playlist.id));

  @override
  Widget build(BuildContext context) {
    final shown = _order.apply(songs);
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoNavigationBar(
                previousPageTitle: 'Playlists',
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
                    widget.playlist.name,
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
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          _device.isMobile ? 16 : 30,
                          _device.isMobile ? 12 : 4,
                          _device.isMobile ? 16 : 30,
                          8,
                        ),
                        sliver: SliverToBoxAdapter(child: _controls()),
                      ),
                      if (_songsLoaded && songs.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text("There's no songs yet.")),
                        ),
                      SliverList.builder(
                        itemBuilder: (context, index) => ValueListenableBuilder(
                          valueListenable: _playingSongId,
                          builder: (context, songId, other) {
                            final song = shown[index];
                            return SongRowView(
                              song: song,
                              isPlaying: song.id == songId,
                              onTap: (song) => ref
                                  .read(playbackProvider.notifier)
                                  .play(
                                    song,
                                    shown,
                                    widget.playlist,
                                    sourceId: widget.playlist.id,
                                  ),
                              position: index + 1,
                              edgePadding: _device.isMobile ? 16 : 30,
                              onLikePressed: _onSongLikePressed,
                              onRatingChanged: _onSongRated,
                              optionsBuilder: (context) => [
                                ContextMenuAction(
                                  entry: ContextMenuEntry.removeFromPlaylist,
                                  icon: const Icon(Icons.playlist_remove),
                                  label: const Text('Remove from playlist'),
                                  run: () => _onRemoveFromPlaylist(song),
                                ),
                                ...contextMenuActions(
                                  context,
                                  ref,
                                  song,
                                  scope: ContextMenuScope.playlistPage,
                                  onLike: _onSongLikePressed,
                                ),
                              ],
                            );
                          },
                        ),
                        itemCount: shown.length,
                      ),
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

  Future<void> _onSongLikePressed(LibraryItem song) async {
    await ref
        .read(mediaServerClientProvider)
        .setFavorite(song.id, favorite: !song.userData.isFavorite);
    ref.read(favouritesChangedProvider.notifier).state++;
    unawaited(_getSongs());
  }

  Future<void> _onSongRated(LibraryItem song, int rating) async {
    await rateItem(ref, song, rating);
    unawaited(_getSongs());
  }

  Future<void> _onRemoveFromPlaylist(LibraryItem song) async {
    final entryId = song.playlistItemId;
    if (entryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uff! Something went wrong...')),
      );
      return;
    }
    await ref
        .read(mediaServerClientProvider)
        .removePlaylistItem(playlistId: widget.playlist.id, entryId: entryId);
    ref.read(downloadSyncProvider).syncPlaylist(widget.playlist.id);
    unawaited(_getSongs());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully removed item from playlist')),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _titleOpacity.dispose();
    _playingSongId.dispose();
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
                widget.playlist.name,
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
        Text(widget.playlist.albumArtist ?? ''),
        Row(
          children: [
            _albumDetails(
              duration: widget.playlist.duration,
              soundsCount: songs.length,
              albumArtist: songs.isNotEmpty ? songs.first.albumArtist : '',
              year: widget.playlist.productionYear,
              divider: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Offstage(
                  offstage: _device.isMobile,
                  child: const Icon(Icons.circle, size: 4),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _albumPanel() => IconTheme.merge(
    data: IconThemeData(size: _device.isMobile ? 24 : 28),
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
                      widget.playlist.name,
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
              Text(widget.playlist.albumArtist ?? ''),
              Row(
                children: [
                  _albumDetails(
                    duration: widget.playlist.duration,
                    soundsCount: songs.length,
                    albumArtist: songs.isNotEmpty
                        ? songs.first.albumArtist
                        : '',
                    year: widget.playlist.productionYear,
                    divider: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Offstage(
                        offstage: _device.isMobile,
                        child: const Icon(Icons.circle, size: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _controls() => PlaylistControls(
    onPlay: _onPlayPlaylistPressed,
    onShuffle: () {
      final playback = ref.read(setPlaybackProvider.notifier);
      playback
          .shufflePlay(
            widget.playlist,
            () => playback.playlistSongs(widget.playlist.id),
          )
          .ignore();
    },
    isPlayLoading: ref.watch(setPlaybackProvider) == widget.playlist.id,
    download: _downloadAlbumButton(),
    sort: PlaylistSortButton(
      order: _order,
      onChanged: (next) =>
          ref
                  .read(playlistSongOrderProvider(widget.playlist.id).notifier)
                  .state =
              next,
    ),
  );

  Future<void> _onPlayPlaylistPressed() async {
    try {
      final playback = ref.read(setPlaybackProvider.notifier);
      final order = ref.read(playlistSongOrderProvider(widget.playlist.id));
      final result = order.isDefault
          ? await playback.playPlaylist(widget.playlist)
          : await playback.playSongs(widget.playlist, order.apply(songs));
      if (result == SetPlaybackResult.empty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nothing to play in "${widget.playlist.name}"'),
          ),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start playing "${widget.playlist.name}"'),
          ),
        );
      }
    }
  }

  Widget _downloadAlbumButton() => CollectionDownloadButton(
    item: widget.playlist,
    songs: () async => songs,
  );

  Widget _albumDetails({
    required Duration duration,
    required int soundsCount,
    int? year,
    String? albumArtist,
    Widget divider = const SizedBox.shrink(),
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
          divider,
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.music, size: 14),
          ),
          Text('$soundsCount songs'),
          if (year != null) ...[
            divider,
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
