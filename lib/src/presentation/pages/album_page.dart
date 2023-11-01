import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/providers/current_album_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';
import 'package:jplayer/src/presentation/widgets/random_queue_button.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
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
  final _currentSongId = ValueNotifier<SongDTO?>(null);
  final _titleKey = GlobalKey(debugLabel: 'title');
  List<SongDTO> songs = [];

  late final ImageService _imageService;

  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isDesktop;

  void _onScroll() {
    final titleContext = _titleKey.currentContext;

    if (titleContext?.mounted ?? false) {
      final scrollPosition = _scrollController.position;
      final scrollableContext = scrollPosition.context.notificationContext!;
      final scrollableRenderBox = scrollableContext.findRenderObject()! as RenderBox;
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
    _imageService = ImageService(serverUrl: ref.read(baseUrlProvider.notifier).state!);
    _getSongs();
    _currentSongId.value = ref.read(audioQueueProvider).currentSong;
    _scrollController.addListener(_onScroll);
  }

  void _getSongs() {
    ref.read(jellyfinApiProvider).getSongs(userId: ref.read(currentUserProvider.notifier).state!.userId, albumId: widget.album.id).then((value) {
      setState(() {
        final items = [...value.data.items]..sort((a, b) => a.indexNumber.compareTo(b.indexNumber));
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

  @override
  Widget build(BuildContext context) {
    ref.listen(audioQueueProvider, (previous, next) {
      _currentSongId.value = next.currentSong;
    });
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
                    ref.read(currentAlbumProvider)!.name,
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
                                  image: _imageService.albumIP(
                                    id: ref.read(currentAlbumProvider)!.id,
                                    tagId: ref.read(currentAlbumProvider)!.imageTags['Primary'],
                                  ),
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
                              image: _imageService.albumIP(id: ref.read(currentAlbumProvider)!.id, tagId: ref.read(currentAlbumProvider)!.imageTags['Primary']),
                              isMobile: _isMobile,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: _isMobile ? 16 : 30,
                            top: _isMobile ? 15 : 35,
                            right: _isMobile ? 16 : 30,
                            bottom: 18,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _albumPanel(),
                          ),
                        ),
                      ],
                      SliverList.builder(
                        itemBuilder: (context, index) => ValueListenableBuilder(
                          valueListenable: _currentSongId,
                          builder: (context, value, child) => PlayerSongView(
                            song: songs[index],
                            isPlaying: songs[index] == value,
                            downloadProgress: null, // index == 2 ? 0.8 : null,
                            onTap: () {
                              ref.read(playbackProvider.notifier).play(songs[index], songs, widget.album);
                            },
                            position: index + 1,
                            onLikePressed: () async {
                              final api = ref.read(jellyfinApiProvider);
                              songs[index].songUserData.isFavorite
                                  ? await api.removeFavorite(userId: ref.read(currentUserProvider.notifier).state!.userId, itemId: songs[index].id)
                                  : await api.saveFavorite(userId: ref.read(currentUserProvider.notifier).state!.userId, itemId: songs[index].id);
                              _getSongs();
                            },
                          ),
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
    _currentSongId.dispose();
  }

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
                          ref.read(currentAlbumProvider)!.name,
                          key: _titleKey,
                          style: TextStyle(
                            fontSize: _isMobile ? 18 : 32,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Offstage(
                        offstage: !_isMobile,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 18),
                          child: Text(
                            ref.read(currentAlbumProvider)!.productionYear.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (songs.isNotEmpty) Text(songs.first.albumArtist ?? ''),
                  _albumDetails(
                    duration: ref.read(currentAlbumProvider)!.duration,
                    soundsCount: songs.length,
                    albumArtist: songs.isNotEmpty ? songs.first.albumArtist : '',
                    year: _isMobile ? null : ref.read(currentAlbumProvider)!.productionYear,
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
    final minutes = (durationInSeconds - hours * Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
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
            child: Icon(JPlayer.clock),
          ),
          Text(
            [
              if (hours > 0) hours,
              minutes,
              seconds.toString().padLeft(2, '0'),
            ].join(':'),
          ),
          divider,
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.music),
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
  bool shouldRebuild(covariant _FadeOutImageDelegate oldDelegate) => image != oldDelegate.image || isMobile != oldDelegate.isMobile;
}
