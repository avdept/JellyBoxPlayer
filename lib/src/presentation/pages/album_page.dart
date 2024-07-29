import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/playlists_provider.dart';
import 'package:jplayer/src/presentation/widgets/random_queue_button.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({required this.album, super.key});
  final ItemDTO album;

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final _scrollController = ScrollController();
  final _titleOpacity = ValueNotifier<double>(0);
  late ValueNotifier<MediaItem?> _currentSong;
  final _titleKey = GlobalKey(debugLabel: 'title');
  List<SongDTO> songs = [];

  late final ImageService _imageService;

  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isDesktop;

  Future<void> _onAddToPlaylistPressed(SongDTO song) async {
    ItemDTO? playlist;

    if (_isDesktop) {
      playlist = await showDialog<ItemDTO>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Choose a playlist',
            textAlign: TextAlign.center,
          ),
          content: _availablePlaylistsList(),
        ),
      );
    } else {
      playlist = await showModalBottomSheet<ItemDTO>(
        context: context,
        clipBehavior: Clip.antiAlias,
        builder: (context) => Scaffold(
          // backgroundColor: ,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _theme.bottomSheetTheme.backgroundColor,
            automaticallyImplyLeading: false,
            title: const Text('Choose a playlist'),
            actions: const [
              CloseButton(),
            ],
          ),
          body: CustomScrollbar(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: _availablePlaylistsList(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (playlist != null) {
      await ref.read(jellyfinApiProvider).addPlaylistItems(
            playlistId: playlist.id,
            userId: ref.read(currentUserProvider)!.userId,
            entryIds: song.id,
          );
      const snackBar = SnackBar(
        backgroundColor: Colors.black87,
        content: Text(
          'Successfully added item to playlist',
          style: TextStyle(color: Colors.white),
        ),
      );
      _getSongs();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
    _currentSong = ValueNotifier<MediaItem?>(null);
    _imageService =
        ImageService(serverUrl: ref.read(baseUrlProvider.notifier).state!);
    _getSongs();
    ref.read(playerProvider).sequenceStateStream.listen((event) {
      if (event != null) {
        if (mounted) {
          _currentSong.value =
              event.sequence[event.currentIndex].tag as MediaItem;
          ref.read(imageSchemeProvider.notifier).state = _imageService.albumIP(
            id: widget.album.id,
            tagId: widget.album.imageTags['Primary'],
          );
        }
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _getSongs() {
    ref
        .read(jellyfinApiProvider)
        .getSongs(
          userId: ref.read(currentUserProvider)!.userId,
          albumId: widget.album.id,
        )
        .then((value) {
      setState(() {
        final items = [...value.data.items]
          ..sort((a, b) => a.indexNumber.compareTo(b.indexNumber));
        songs = items;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _screenSize = MediaQuery.sizeOf(context);

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isDesktop = deviceType == DeviceScreenType.desktop;
  }

  ImageProvider get albumCover => _imageService.albumIP(
      id: widget.album.id, tagId: widget.album.imageTags['Primary']);

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
                  horizontal: _isMobile ? 16 : 30,
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
                      fontSize: _isMobile ? 14 : 20,
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
                      if (_isDesktop)
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
                            horizontal: _isMobile ? 16 : 30,
                          ),
                          sliver: SliverPersistentHeader(
                            pinned: true,
                            delegate: _FadeOutImageDelegate(
                              image: albumCover,
                              isMobile: _isMobile,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: _isMobile ? 16 : 30,
                            top: _isMobile ? 15 : 35,
                            right: _isMobile ? 16 : 30,
                            bottom: _isMobile ? 0 : 18,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _albumPanelMobile(),
                          ),
                        ),
                      ],
                      SliverList.builder(
                        itemBuilder: (context, index) => ValueListenableBuilder(
                          valueListenable: _currentSong,
                          builder: (context, item, other) {
                            final song = songs[index];
                            return PlayerSongView(
                              song: song,
                              isPlaying: item != null && song.id == item.id,
                              downloadProgress:
                                  null, // index == 2 ? 0.8 : null,
                              onTap: (song) => ref
                                  .read(playbackProvider.notifier)
                                  .play(song, songs, widget.album),
                              position: index + 1,
                              onLikePressed: (song) async {
                                final api = ref.read(jellyfinApiProvider);
                                final callback = song.songUserData.isFavorite
                                    ? api.removeFavorite
                                    : api.saveFavorite;
                                await callback.call(
                                  userId: ref.read(currentUserProvider)!.userId,
                                  itemId: song.id,
                                );
                                _getSongs();
                              },
                              optionsBuilder: (context) => [
                                PopupMenuItem(
                                  onTap: () => _onAddToPlaylistPressed(song),
                                  child: const Text('Add to playlist'),
                                ),
                              ],
                            );
                          },
                        ),
                        itemCount: songs.length,
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

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _titleOpacity.dispose();
    _currentSong.dispose();
  }

  Widget _albumPanelMobile() => IconTheme(
        data: _theme.iconTheme.copyWith(size: _isMobile ? 24 : 28),
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
                      fontSize: _isMobile ? 18 : 32,
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
                  albumArtist: songs.isNotEmpty ? songs.first.albumArtist : '',
                  year: widget.album.productionYear,
                  divider: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Offstage(
                      offstage: _isMobile,
                      child: const Icon(Icons.circle, size: 4),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // _downloadAlbumButton(),
                    const RandomQueueButton(),
                    SizedBox.square(
                      dimension: _isMobile ? 38 : 48,
                      child: _playAlbumButton(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  Widget _albumPanel() => IconTheme(
        data: _theme.iconTheme.copyWith(size: _isMobile ? 24 : 28),
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
                            fontSize: _isMobile ? 18 : 32,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(widget.album.albumArtist ?? ''),
                  Row(
                    children: [
                      _albumDetails(
                        duration: widget.album.duration,
                        soundsCount: songs.length,
                        albumArtist:
                            songs.isNotEmpty ? songs.first.albumArtist : '',
                        year: widget.album.productionYear,
                        divider: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Offstage(
                            offstage: _isMobile,
                            child: const Icon(Icons.circle, size: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: _isDesktop ? 35 : 32),
            if (_isDesktop)
              Container()
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
                spacing: _isMobile ? 6 : 32,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _downloadAlbumButton(),
                  const RandomQueueButton(),
                  SizedBox.square(
                    dimension: _isMobile ? 40 : 48,
                    child: _playAlbumButton(),
                  ),
                ],
              ),
          ],
        ),
      );

  Widget _playAlbumButton() => PlayButton(
        onPressed: () {},
      );

  Widget _downloadAlbumButton() => IconButton(
        onPressed: () {},
        icon: const Icon(JPlayer.download),
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
    final minutes = (durationInSeconds - hours * Duration.secondsPerHour) ~/
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

  Widget _availablePlaylistsList({EdgeInsets padding = EdgeInsets.zero}) {
    return Consumer(
      builder: (context, ref, child) {
        final data = ref.watch(playlistsProvider);

        if (data.isLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        return ListBody(
          children: [
            SizedBox(height: padding.top),
            for (final playlist in data.value.items)
              SimpleListTile(
                onTap: () => Navigator.of(context).pop(playlist),
                padding: padding.copyWith(top: 6, bottom: 6),
                title: Text(
                  playlist.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: padding.bottom),
          ],
        );
      },
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
