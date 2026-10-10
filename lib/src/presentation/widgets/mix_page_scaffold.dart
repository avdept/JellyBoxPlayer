import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/cover_mosaic.dart';
import 'package:jplayer/src/presentation/widgets/custom_scrollbar.dart';
import 'package:jplayer/src/presentation/widgets/gradient_background.dart';
import 'package:jplayer/src/presentation/widgets/play_button.dart';
import 'package:jplayer/src/presentation/widgets/random_queue_button.dart';

class MixPageScaffold extends StatefulWidget {
  const MixPageScaffold({
    required this.name,
    required this.songs,
    required this.coverImages,
    required this.onPlay,
    required this.slivers,
    this.subtitle,
    this.previousPageTitle,
    this.isPlayLoading = false,
    this.songCount,
    this.onLoadMore,
    this.navTrailing,
    this.actions = const [],
    super.key,
  });

  final String name;
  final String? subtitle;
  final String? previousPageTitle;
  final List<LibraryItem> songs;
  final List<ImageProvider> coverImages;
  final VoidCallback onPlay;
  final bool isPlayLoading;
  final int? songCount;
  final Future<void> Function()? onLoadMore;
  final Widget? navTrailing;
  final List<Widget> actions;
  final List<Widget> slivers;

  @override
  State<MixPageScaffold> createState() => _MixPageScaffoldState();
}

class _MixPageScaffoldState extends State<MixPageScaffold> {
  final _scrollController = ScrollController();
  final _titleOpacity = ValueNotifier<double>(0);
  final _titleKey = GlobalKey(debugLabel: 'title');
  var _loadingMore = false;

  late ThemeData _theme;
  late DeviceType _device;

  double get _edge => _device.isMobile ? 16 : 30;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  void _onScroll() {
    _loadMoreIfNearEnd();
    final titleContext = _titleKey.currentContext;
    if (!(titleContext?.mounted ?? false)) return;
    final scrollableContext =
        _scrollController.position.context.notificationContext!;
    final scrollableBox = scrollableContext.findRenderObject()! as RenderBox;
    final titleBox = titleContext!.findRenderObject()! as RenderBox;
    final titlePosition = titleBox.localToGlobal(
      Offset.zero,
      ancestor: scrollableBox,
    );
    final titleHeight = titleContext.size!.height;
    final visibleFraction = (titlePosition.dy + titleHeight) / titleHeight;
    _titleOpacity.value = 1 - min(max(visibleFraction, 0), 1);
  }

  void _loadMoreIfNearEnd() {
    final loadMore = widget.onLoadMore;
    if (loadMore == null || _loadingMore) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels >= 300) return;
    _loadingMore = true;
    loadMore().whenComplete(() => _loadingMore = false);
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
                previousPageTitle: widget.previousPageTitle,
                backgroundColor: Colors.transparent,
                enableBackgroundFilterBlur: false,
                padding: EdgeInsetsDirectional.symmetric(horizontal: _edge),
                trailing: widget.navTrailing,
                middle: ValueListenableBuilder(
                  valueListenable: _titleOpacity,
                  builder: (context, opacity, child) => Transform.translate(
                    offset: Offset(0, 8 - 8 * opacity),
                    child: Opacity(opacity: opacity, child: child),
                  ),
                  child: Text(
                    widget.name,
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
                        _desktopHeader()
                      else
                        ..._stackedHeader(),
                      ...widget.slivers,
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

  Widget _desktopHeader() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox.square(
            dimension: 254,
            child: CoverMosaic(images: widget.coverImages),
          ),
          const SizedBox(width: 38),
          Expanded(child: _desktopPanel()),
        ],
      ),
    ),
  );

  List<Widget> _stackedHeader() => [
    SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: _edge),
      sliver: SliverPersistentHeader(
        pinned: true,
        delegate: _FadeOutCoverDelegate(
          images: widget.coverImages,
          isMobile: _device.isMobile,
        ),
      ),
    ),
    SliverPadding(
      padding: EdgeInsets.only(
        left: _edge,
        top: _device.isMobile ? 15 : 35,
        right: _edge,
        bottom: _device.isMobile ? 0 : 18,
      ),
      sliver: SliverToBoxAdapter(child: _stackedPanel()),
    ),
  ];

  Widget _title() => Row(
    children: [
      Flexible(
        child: Text(
          widget.name,
          key: _titleKey,
          style: TextStyle(
            fontSize: _device.isMobile ? 18 : 32,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    ],
  );

  Widget _desktopPanel() => IconTheme.merge(
    data: const IconThemeData(size: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(),
              Text(widget.subtitle ?? ''),
              Row(children: [_details()]),
            ],
          ),
        ),
        if (widget.actions.isNotEmpty) ...[
          const SizedBox(width: 35),
          Row(mainAxisSize: MainAxisSize.min, children: widget.actions),
        ],
      ],
    ),
  );

  Widget _stackedPanel() => IconTheme.merge(
    data: IconThemeData(size: _device.isMobile ? 24 : 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _title(),
        Text(widget.subtitle ?? ''),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _details(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ...widget.actions,
                const RandomQueueButton(),
                SizedBox.square(
                  dimension: _device.isMobile ? 38 : 48,
                  child: PlayButton(
                    isLoading: widget.isPlayLoading,
                    onPressed: widget.onPlay,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  Widget _details() {
    final count = widget.songCount ?? widget.songs.length;
    final total = widget.songs.fold(
      Duration.zero,
      (sum, song) => sum + song.duration,
    );
    final hours = total.inHours;
    final minutes = total.inMinutes % Duration.minutesPerHour;
    final seconds = total.inSeconds % Duration.secondsPerMinute;
    final showDuration = widget.songs.length >= count;

    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDuration) ...[
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.circle,
                size: 4,
                color: _theme.colorScheme.onPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(JPlayer.music, size: 14),
          ),
          Text('$count songs'),
        ],
      ),
    );
  }
}

class _FadeOutCoverDelegate extends SliverPersistentHeaderDelegate {
  const _FadeOutCoverDelegate({required this.images, required this.isMobile});

  final List<ImageProvider> images;
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
  ) => Opacity(
    opacity: max((maxExtent - shrinkOffset * 1.5) / maxExtent, 0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox.square(
        dimension: max(maxExtent - shrinkOffset, 0),
        child: CoverMosaic(images: images),
      ),
    ),
  );

  @override
  bool shouldRebuild(covariant _FadeOutCoverDelegate oldDelegate) =>
      images != oldDelegate.images || isMobile != oldDelegate.isMobile;
}
