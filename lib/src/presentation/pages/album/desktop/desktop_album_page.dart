import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/animated_cover_provider.dart';
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
  double get edgePadding => device.isTablet ? 16 : 30;

  @override
  double get navTitleFontSize => 20;

  @override
  double get discHeaderFontSize => 18;

  @override
  double get sectionTitleFontSize => 24;

  Uri? _animatedCover() =>
      ref.watch(desktopAnimatedCoverProvider(album)).valueOrNull;

  @override
  Widget build(BuildContext context) {
    return DesktopPageColumn(
      controller: scrollController,
      titleKey: titleKey,
      title: album.name,
      previousPageTitle: 'Albums',
      edgePadding: edgePadding,
      titleFontSize: navTitleFontSize,
      slivers: [
        if (device.isDesktop) _headerSliver() else ..._tabletHeaderSlivers(),
        ...contentSlivers(),
      ],
    );
  }

  Widget _headerSliver() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CoverWithVideo(
            image: albumCover,
            height: 254,
            video: _animatedCover(),
          ),
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
        delegate: _FadeOutImageDelegate(
          image: albumCover,
          video: _animatedCover(),
        ),
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
                  albumRatingStars(size: 22, spacing: 2),
                ],
              ),
              albumArtists(
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: albumGenres(const TextStyle(fontSize: 15)),
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
            albumRatingStars(size: 26, spacing: 4),
          ],
        ),
        Builder(
          builder: (context) =>
              albumArtists(DefaultTextStyle.of(context).style),
        ),
        Builder(
          builder: (context) => albumGenres(DefaultTextStyle.of(context).style),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            albumDetails(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                resumeAlbumButton(),
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

class _CoverWithVideo extends StatelessWidget {
  const _CoverWithVideo({
    required this.image,
    required this.height,
    required this.video,
    this.videoWidth,
  });

  final ImageProvider image;
  final double height;
  final Uri? video;
  final double? videoWidth;

  @override
  Widget build(BuildContext context) {
    final video = this.video;
    return Stack(
      children: [
        Image(image: image, height: height),
        if (video != null)
          Positioned.fill(
            child: AnimatedCoverVideo(
              url: video,
              maxWidth: videoWidth ?? height,
            ),
          ),
      ],
    );
  }
}

class _FadeOutImageDelegate extends SliverPersistentHeaderDelegate {
  const _FadeOutImageDelegate({required this.image, this.video});

  final ImageProvider image;
  final Uri? video;

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
    final height = max(maxExtent - shrinkOffset, 0).toDouble();
    final opacity = max(
      (maxExtent - shrinkOffset * 1.5) / maxExtent,
      0,
    ).toDouble();
    if (video == null) {
      return Image(
        image: image,
        height: height,
        opacity: AlwaysStoppedAnimation(opacity),
      );
    }
    return Opacity(
      opacity: opacity,
      child: Center(
        child: _CoverWithVideo(
          image: image,
          height: height,
          video: video,
          videoWidth: maxExtent,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FadeOutImageDelegate oldDelegate) =>
      image != oldDelegate.image || video != oldDelegate.video;
}
