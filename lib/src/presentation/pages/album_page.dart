import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  final _scrollController = ScrollController();
  final _titleOpacity = ValueNotifier<double>(0);
  final _titleKey = GlobalKey(debugLabel: 'title');

  late ThemeData _theme;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isDesktop;

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
                    'Album name',
                    style: TextStyle(
                      fontSize: _isMobile ? 14 : 20,
                      color: _theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (event) {
                    final titleContext = _titleKey.currentContext;

                    if (titleContext?.mounted ?? false) {
                      final scrollableRenderBox =
                          event.context!.findRenderObject()! as RenderBox;
                      final titleRenderBox =
                          titleContext!.findRenderObject()! as RenderBox;
                      final titlePosition = titleRenderBox.localToGlobal(
                        Offset.zero,
                        ancestor: scrollableRenderBox,
                      );
                      final titleHeight = titleContext.size!.height;
                      final visibleFraction =
                          (titlePosition.dy + titleHeight) / titleHeight;

                      _titleOpacity.value = 1 - min(max(visibleFraction, 0), 1);
                    }

                    return false;
                  },
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
                                Image.asset(Images.albumSample, height: 254),
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
                              image: const AssetImage(Images.albumSample),
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
                        itemBuilder: (context, index) => PlayerSongView(
                          name: 'Chi Shenidi? (feat. Hichkas)',
                          singer: 'Fadaei',
                          isPlaying: index == 1,
                          isFavorite: index == 0,
                          downloadProgress: index == 2 ? 0.8 : null,
                          onTap: () {},
                          onLikePressed: () {},
                        ),
                        itemCount: 30,
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
  }

  Widget _albumPanel() => IconTheme(
        data: _theme.iconTheme.copyWith(size: _isMobile ? 24 : 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Album name',
                          key: _titleKey,
                          style: TextStyle(
                            fontSize: _isMobile ? 18 : 42,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Offstage(
                        offstage: !_isMobile,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 18),
                          child: Text(
                            '2023',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _albumDetails(
                    duration: const Duration(
                      minutes: 42,
                      seconds: 12,
                    ),
                    soundsCount: 13,
                    year: _isMobile ? null : 2023,
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
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox.square(
                      dimension: 65,
                      child: _playAlbumButton(),
                    ),
                    _downloadAlbumButton(),
                  ],
                ),
              )
            else
              Wrap(
                spacing: _isMobile ? 6 : 32,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _downloadAlbumButton(),
                  _randomQueueButton(),
                  SizedBox.square(
                    dimension: _isMobile ? 40 : 48,
                    child: _playAlbumButton(),
                  ),
                ],
              ),
          ],
        ),
      );

  Widget _playAlbumButton() => MaterialButton(
        onPressed: () {},
        color: const Color(0xFF0066FF),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.play_arrow_outlined),
      );

  Widget _downloadAlbumButton() => IconButton(
        onPressed: () {},
        icon: const Icon(JPlayer.download),
      );

  Widget _randomQueueButton() => IconButton(
        onPressed: () {},
        icon: const Icon(JPlayer.mix),
      );

  Widget _albumDetails({
    required Duration duration,
    required int soundsCount,
    int? year,
    Widget divider = const SizedBox.shrink(),
  }) {
    final durationInSeconds = duration.inSeconds;
    final hours = durationInSeconds ~/ Duration.secondsPerHour;
    final minutes = durationInSeconds ~/ Duration.secondsPerMinute;
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
  bool shouldRebuild(covariant _FadeOutImageDelegate oldDelegate) =>
      image != oldDelegate.image || isMobile != oldDelegate.isMobile;
}
