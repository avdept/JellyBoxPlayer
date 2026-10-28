import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/custom_scrollbar.dart';
import 'package:jplayer/src/presentation/widgets/gradient_background.dart';
import 'package:jplayer/src/presentation/widgets/scroll_title_fade.dart';

class DesktopPageColumn extends StatefulWidget {
  const DesktopPageColumn({
    required this.controller,
    required this.titleKey,
    required this.title,
    required this.slivers,
    this.previousPageTitle,
    this.edgePadding = 30,
    this.titleFontSize = 20,
    super.key,
  });

  final ScrollController controller;
  final GlobalKey titleKey;
  final String title;
  final List<Widget> slivers;
  final String? previousPageTitle;
  final double edgePadding;
  final double titleFontSize;

  @override
  State<DesktopPageColumn> createState() => _DesktopPageColumnState();
}

class _DesktopPageColumnState extends State<DesktopPageColumn> {
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
              Expanded(
                child: CustomScrollbar(
                  controller: widget.controller,
                  child: CustomScrollView(
                    controller: widget.controller,
                    slivers: widget.slivers,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
