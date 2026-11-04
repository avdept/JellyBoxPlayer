import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/blurred_cover_art.dart';
import 'package:jplayer/src/presentation/widgets/custom_scrollbar.dart';
import 'package:jplayer/src/presentation/widgets/gradient_background.dart';
import 'package:jplayer/src/presentation/widgets/scroll_title_fade.dart';

class MobileCoverScaffold extends StatefulWidget {
  const MobileCoverScaffold({
    required this.controller,
    required this.titleKey,
    required this.title,
    required this.cover,
    required this.panel,
    required this.slivers,
    this.previousPageTitle,
    this.coverOverlay,
    this.tint,
    this.edgePadding = 16,
    this.titleFontSize = 14,
    super.key,
  });

  final ScrollController controller;
  final GlobalKey titleKey;
  final String title;
  final ImageProvider cover;
  final Widget panel;
  final List<Widget> slivers;
  final String? previousPageTitle;
  final Widget? coverOverlay;
  final Color? tint;
  final double edgePadding;
  final double titleFontSize;

  @override
  State<MobileCoverScaffold> createState() => _MobileCoverScaffoldState();
}

class _MobileCoverScaffoldState extends State<MobileCoverScaffold> {
  static const _panelTopPadding = 15.0;

  final GlobalKey _panelKey = GlobalKey(debugLabel: 'panel');
  final ValueNotifier<double> _barOpacity = ValueNotifier<double>(0);
  late final ScrollTitleFade _fade = ScrollTitleFade(
    controller: widget.controller,
    titleKey: widget.titleKey,
  );
  var _coverExtent = 0.0;
  var _navBarHeight = 0.0;
  var _panelOverlap = 0.0;
  var _panelMeasured = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateBar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measurePanel());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coverExtent = MediaQuery.sizeOf(context).width;
    _navBarHeight =
        MediaQuery.paddingOf(context).top + kMinInteractiveDimensionCupertino;
    _fade.inset = _navBarHeight;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateBar);
    _barOpacity.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _updateBar() {
    if (!widget.controller.hasClients) return;
    final contentTop = _coverExtent - _panelOverlap - widget.controller.offset;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Opacity(
          opacity: _panelMeasured ? 1 : 0,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: widget.tint ?? Colors.transparent),
            duration: const Duration(milliseconds: 600),
            builder: (context, tint, child) => _tinted(context, tint!),
          ),
        ),
      ),
    );
  }

  Widget _tinted(BuildContext context, Color tint) {
    final theme = Theme.of(context);
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
          controller: widget.controller,
          child: CustomScrollView(
            controller: widget.controller,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: _coverExtent - _panelOverlap),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  widget.edgePadding,
                  _panelTopPadding,
                  widget.edgePadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: KeyedSubtree(key: _panelKey, child: widget.panel),
                ),
              ),
              ...widget.slivers,
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _floatingNavBar(theme, base),
        ),
      ],
    );
  }

  Widget _cover(Color background) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, child) {
      final offset = widget.controller.hasClients
          ? widget.controller.offset
          : 0.0;
      final stretch = max(-offset, 0);
      final travel = _coverExtent - _panelOverlap - _navBarHeight;
      final progress = travel > 0 ? (offset / travel).clamp(0.0, 1.0) : 0.0;
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Opacity(
          opacity: 1 - progress,
          child: BlurredCoverArt(
            image: widget.cover,
            width: _coverExtent,
            height: _coverExtent + stretch,
            background: background,
            overlay: widget.coverOverlay,
          ),
        ),
      );
    },
  );

  Widget _floatingNavBar(ThemeData theme, Color background) =>
      ValueListenableBuilder(
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
        child: CupertinoNavigationBar(
          previousPageTitle: widget.previousPageTitle,
          backgroundColor: Colors.transparent,
          enableBackgroundFilterBlur: false,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: widget.edgePadding,
          ),
          middle: FadingNavTitle(
            opacity: _fade,
            child: Text(
              widget.title,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: widget.titleFontSize,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      );
}
