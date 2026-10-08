import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/pages/album/album_page.dart';
import 'package:jplayer/src/presentation/pages/album/album_page_state.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class DesktopAlbumPage extends ConsumerStatefulWidget {
  const DesktopAlbumPage({
    required this.album,
    this.testKeys,
    super.key,
  });

  final LibraryItem album;
  final AlbumPageKeys? testKeys;

  @override
  ConsumerState<DesktopAlbumPage> createState() => _DesktopAlbumPageState();
}

class _DesktopAlbumPageState extends ConsumerState<DesktopAlbumPage>
    with AlbumPageState {
  @override
  LibraryItem get album => widget.album;

  @override
  AlbumPageKeys? get testKeys => widget.testKeys;

  @override
  double get edgePadding => 30;

  @override
  double get navTitleFontSize => 20;

  @override
  double get discHeaderFontSize => 18;

  @override
  double get sectionTitleFontSize => 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              navBar(),
              Expanded(
                child: CustomScrollbar(
                  controller: scrollController,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      if (device.isDesktop)
                        _headerSliver()
                      else
                        ..._tabletHeaderSlivers(),
                      ...contentSlivers(),
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

  Widget _headerSliver() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image(image: albumCover, height: 254),
          const SizedBox(width: 38),
          Expanded(child: _panel()),
        ],
      ),
    ),
  );

  List<Widget> _tabletHeaderSlivers() => [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      sliver: SliverPersistentHeader(
        pinned: true,
        delegate: _FadeOutImageDelegate(image: albumCover),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(30, 35, 30, 18),
      sliver: SliverToBoxAdapter(child: _tabletPanel()),
    ),
  ];

  Widget _panel() => IconTheme.merge(
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
                      album.name,
                      key: titleKey,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: albumArtists(
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
                ),
              ),
              Row(children: [albumDetails()]),
            ],
          ),
        ),
        const SizedBox(width: 35),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [downloadAlbumButton(), likeAlbumButton()],
        ),
      ],
    ),
  );

  Widget _tabletPanel() => IconTheme.merge(
    data: const IconThemeData(size: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                album.name,
                key: titleKey,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        Builder(
          builder: (context) =>
              albumArtists(DefaultTextStyle.of(context).style),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            albumDetails(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                downloadAlbumButton(),
                likeAlbumButton(),
                SizedBox.square(dimension: 48, child: playAlbumButton()),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _FadeOutImageDelegate extends SliverPersistentHeaderDelegate {
  const _FadeOutImageDelegate({required this.image});

  final ImageProvider image;

  @override
  double get maxExtent => 299;

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
      image != oldDelegate.image;
}
