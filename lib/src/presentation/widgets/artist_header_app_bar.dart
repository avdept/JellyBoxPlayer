import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/scroll_title_fade.dart';

class ArtistHeaderAppBar extends StatefulWidget {
  const ArtistHeaderAppBar({
    required this.controller,
    required this.titleKey,
    required this.name,
    required this.titleImage,
    this.barColor,
    super.key,
  });

  final ScrollController controller;
  final GlobalKey titleKey;
  final String name;
  final ImageProvider titleImage;
  final Color? barColor;

  @override
  State<ArtistHeaderAppBar> createState() => _ArtistHeaderAppBarState();
}

class _ArtistHeaderAppBarState extends State<ArtistHeaderAppBar> {
  late final ScrollTitleFade _fade = ScrollTitleFade(
    controller: widget.controller,
    titleKey: widget.titleKey,
  );

  static const _barFadeDistance = 48.0;

  double get _barOpacity => widget.controller.hasClients
      ? (widget.controller.offset / _barFadeDistance).clamp(0.0, 1.0)
      : 0;

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      title: FadingNavTitle(
        opacity: _fade,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image(
                image: widget.titleImage,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      flexibleSpace: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => ClipRect(
          child: BackdropFilter(
            enabled: _barOpacity > 0,
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ColoredBox(
              color: (widget.barColor ?? theme.scaffoldBackgroundColor)
                  .withValues(alpha: 0.9 * _barOpacity),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class ArtistHeaderBody extends StatelessWidget {
  const ArtistHeaderBody({
    required this.image,
    required this.panel,
    required this.headerHeight,
    required this.horizontalPadding,
    required this.isMobile,
    super.key,
  });

  static const avatarSize = 120.0;
  static const avatarTop = 32.0;

  final Widget image;
  final Widget panel;
  final double headerHeight;
  final double horizontalPadding;
  final bool isMobile;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: SizedBox(
      height: headerHeight - kToolbarHeight,
      child: isMobile ? _mobile() : _desktop(),
    ),
  );

  Widget _mobile() => Padding(
    padding: const EdgeInsets.only(left: 20, top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: AspectRatio(aspectRatio: 1, child: image)),
        Flexible(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: panel,
          ),
        ),
      ],
    ),
  );

  Widget _desktop() => Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: avatarTop),
        SizedBox.square(dimension: avatarSize, child: image),
        const Spacer(),
        panel,
        const SizedBox(height: 8),
      ],
    ),
  );
}
