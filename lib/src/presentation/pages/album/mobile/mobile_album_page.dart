import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/album/album_page.dart';
import 'package:jplayer/src/presentation/pages/album/album_page_state.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';

class MobileAlbumPage extends ConsumerStatefulWidget {
  const MobileAlbumPage({
    required this.album,
    this.testKeys,
    super.key,
  });

  final LibraryItem album;
  final AlbumPageKeys? testKeys;

  @override
  ConsumerState<MobileAlbumPage> createState() => _MobileAlbumPageState();
}

class _MobileAlbumPageState extends ConsumerState<MobileAlbumPage>
    with AlbumPageState {
  @override
  LibraryItem get album => widget.album;

  @override
  AlbumPageKeys? get testKeys => widget.testKeys;

  @override
  double get edgePadding => 16;

  @override
  double get navTitleFontSize => 14;

  @override
  double get discHeaderFontSize => 16;

  @override
  double get sectionTitleFontSize => 20;

  @override
  Color? get playingRowColor =>
      _tintEnabled ? Colors.white.withValues(alpha: 0.1) : null;

  bool get _tintEnabled => ref.watch(settingProvider(AppSetting.albumArtTint));

  Uri? _animatedCover() {
    if (ref.watch(networkTypeProvider) != NetworkType.wifi) return null;
    return ref.watch(animatedCoverProvider(album)).valueOrNull;
  }

  Color? _coverTint() {
    if (!_tintEnabled) return null;
    final color = ref.watch(coverEdgeColorProvider(album)).valueOrNull;
    if (color == null) return null;
    return Color.lerp(Colors.black, color, 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final video = _animatedCover();
    return MobileCoverScaffold(
      controller: scrollController,
      titleKey: titleKey,
      title: album.name,
      previousPageTitle: 'Albums',
      cover: albumCover,
      coverOverlay: video == null
          ? null
          : AnimatedCoverVideo(
              url: video,
              maxWidth: MediaQuery.sizeOf(context).width,
            ),
      tint: _coverTint(),
      panel: _panel(),
      slivers: contentSlivers(),
      edgePadding: edgePadding,
      titleFontSize: navTitleFontSize,
    );
  }

  Widget _panel() => IconTheme.merge(
    data: const IconThemeData(size: 24),
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
                  fontSize: 18,
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
                SizedBox.square(dimension: 38, child: playAlbumButton()),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
