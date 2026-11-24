import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/floating_page_layout.dart';
import 'package:jplayer/src/presentation/widgets/scroll_title_fade.dart';

class DesktopPageColumn extends StatefulWidget {
  const DesktopPageColumn({
    required this.controller,
    required this.titleKey,
    required this.title,
    required this.slivers,
    this.previousPageTitle,
    this.titleImage,
    this.edgePadding = 30,
    this.titleFontSize = 20,
    super.key,
  });

  final ScrollController controller;
  final GlobalKey titleKey;
  final String title;
  final List<Widget> slivers;
  final String? previousPageTitle;
  final ImageProvider? titleImage;
  final double edgePadding;
  final double titleFontSize;

  @override
  State<DesktopPageColumn> createState() => _DesktopPageColumnState();
}

class _DesktopPageColumnState extends State<DesktopPageColumn> {
  static const _titleImageSize = 28.0;

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
  Widget build(BuildContext context) => FloatingPageLayout(
    controller: widget.controller,
    titleFade: _fade,
    previousPageTitle: widget.previousPageTitle,
    edgePadding: widget.edgePadding,
    slivers: widget.slivers,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        if (widget.titleImage case final image?)
          Image(
            image: image,
            width: _titleImageSize,
            height: _titleImageSize,
            fit: BoxFit.cover,
          ),
        Flexible(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: widget.titleFontSize,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
