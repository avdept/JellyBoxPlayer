import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/album/album_page.dart';
import 'package:jplayer/src/presentation/pages/album/album_page_state.dart';
import 'package:jplayer/src/presentation/pages/album/mobile/blurred_cover_art.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

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
  static const _panelTopPadding = 15.0;

  final GlobalKey _panelKey = GlobalKey(debugLabel: 'panel');
  final ValueNotifier<double> _barOpacity = ValueNotifier<double>(0);
  var _coverExtent = 0.0;
  var _navBarHeight = 0.0;
  var _panelOverlap = 0.0;
  var _panelMeasured = false;

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
  double get titleInset => _navBarHeight;

  @override
  Color? get playingRowColor =>
      _tintEnabled ? Colors.white.withValues(alpha: 0.1) : null;

  bool get _tintEnabled => ref.watch(settingProvider(AppSetting.albumArtTint));

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_updateBar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measurePanel());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coverExtent = MediaQuery.sizeOf(context).width;
    _navBarHeight =
        MediaQuery.paddingOf(context).top + kMinInteractiveDimensionCupertino;
  }

  @override
  void dispose() {
    _barOpacity.dispose();
    super.dispose();
  }

  void _updateBar() {
    if (!scrollController.hasClients) return;
    final contentTop = _coverExtent - _panelOverlap - scrollController.offset;
    _barOpacity.value = (1 - (contentTop - _navBarHeight) / 24).clamp(0, 1);
  }

  void _measurePanel() {
    if (!mounted) return;
    final panelHeight = _panelKey.currentContext?.size?.height;
    setState(() {
      if (panelHeight != null) {
        _panelOverlap = min(panelHeight + _panelTopPadding, _coverExtent);
      }
      _panelMeasured = true;
    });
  }

  Color? _coverTint() {
    if (!_tintEnabled) return null;
    final color = ref.watch(coverEdgeColorProvider(album)).valueOrNull;
    if (color == null) return null;
    return Color.lerp(Colors.black, color, 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Opacity(
          opacity: _panelMeasured ? 1 : 0,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: _coverTint() ?? Colors.transparent),
            duration: const Duration(milliseconds: 600),
            builder: (context, tint, child) => _tinted(tint!),
          ),
        ),
      ),
    );
  }

  Widget _tinted(Color tint) {
    final base = Color.alphaBlend(tint, theme.scaffoldBackgroundColor);
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _coverExtent * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tint, tint, tint.withValues(alpha: 0)],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),
        _cover(base),
        CustomScrollbar(
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: _coverExtent - _panelOverlap),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  _panelTopPadding,
                  16,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: KeyedSubtree(key: _panelKey, child: _panel()),
                ),
              ),
              ...contentSlivers(),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _floatingNavBar(base),
        ),
      ],
    );
  }

  Widget _cover(Color background) => ListenableBuilder(
    listenable: scrollController,
    builder: (context, child) {
      final offset = scrollController.hasClients
          ? scrollController.offset
          : 0.0;
      final stretch = max(-offset, 0);
      final travel = _coverExtent - _panelOverlap - _navBarHeight;
      final progress = (offset / travel).clamp(0.0, 1.0);
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Opacity(
          opacity: 1 - progress,
          child: BlurredCoverArt(
            image: albumCover,
            width: _coverExtent,
            height: _coverExtent + stretch,
            background: background,
          ),
        ),
      );
    },
  );

  Widget _floatingNavBar(Color background) => ValueListenableBuilder(
    valueListenable: _barOpacity,
    builder: (context, opacity, child) => ClipRect(
      child: BackdropFilter(
        enabled: opacity > 0,
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ColoredBox(
          color: background.withValues(alpha: 0.8 * opacity),
          child: child,
        ),
      ),
    ),
    child: navBar(),
  );

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
