import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/scroll_title_fade.dart';

class ArtistHeaderAppBar extends StatefulWidget {
  const ArtistHeaderAppBar({
    required this.controller,
    required this.titleKey,
    required this.name,
    required this.titleImage,
    required this.image,
    required this.panel,
    required this.headerHeight,
    required this.horizontalPadding,
    required this.isMobile,
    this.backdrop,
    super.key,
  });

  final ScrollController controller;
  final GlobalKey titleKey;
  final String name;
  final ImageProvider titleImage;
  final Widget image;
  final Widget panel;
  final double headerHeight;
  final double horizontalPadding;
  final bool isMobile;
  final Widget? backdrop;

  @override
  State<ArtistHeaderAppBar> createState() => _ArtistHeaderAppBarState();
}

class _ArtistHeaderAppBarState extends State<ArtistHeaderAppBar> {
  late final ScrollTitleFade _fade = ScrollTitleFade(
    controller: widget.controller,
    titleKey: widget.titleKey,
  );

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
      floating: true,
      pinned: true,
      expandedHeight: widget.headerHeight,
      backgroundColor: Colors.transparent,
      flexibleSpace: ValueListenableBuilder(
        valueListenable: _fade,
        builder: (context, opacity, child) => ClipRect(
          child: BackdropFilter(
            enabled: opacity > 0,
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor.withValues(
                alpha: 0.8 * opacity,
              ),
              child: child,
            ),
          ),
        ),
        child: FlexibleSpaceBar(
          collapseMode: CollapseMode.pin,
          background: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              if (widget.backdrop case final backdrop?)
                Positioned(
                  left: 0,
                  right: 0,
                  top: widget.isMobile ? -60 : 0,
                  height: widget.isMobile ? 340 : widget.headerHeight,
                  child: backdrop,
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: widget.isMobile ? 20 : widget.horizontalPadding,
                  top: 60,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: AspectRatio(aspectRatio: 1, child: widget.image),
                    ),
                    Flexible(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isMobile
                              ? 16
                              : widget.horizontalPadding,
                        ),
                        child: widget.panel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
