import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/custom_scrollbar.dart';
import 'package:jplayer/src/presentation/widgets/floating_panels.dart';
import 'package:jplayer/src/presentation/widgets/gradient_background.dart';
import 'package:jplayer/src/presentation/widgets/scroll_title_fade.dart';

class FloatingPageLayout extends StatelessWidget {
  const FloatingPageLayout({
    required this.controller,
    required this.title,
    required this.titleFade,
    required this.slivers,
    this.previousPageTitle,
    this.edgePadding = 30,
    this.trailing,
    super.key,
  });

  static const _hardBorder = Border(
    bottom: BorderSide(color: Color(0x4D000000), width: 0),
  );

  final ScrollController controller;
  final Widget title;
  final ValueListenable<double> titleFade;
  final List<Widget> slivers;
  final String? previousPageTitle;
  final double edgePadding;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final floating = FloatingPanels.enabled(context);
    final bar = CupertinoNavigationBar(
      border: floating ? null : _hardBorder,
      previousPageTitle: previousPageTitle,
      backgroundColor: Colors.transparent,
      enableBackgroundFilterBlur: false,
      padding: EdgeInsetsDirectional.symmetric(horizontal: edgePadding),
      middle: FadingNavTitle(opacity: titleFade, child: title),
      trailing: switch (trailing) {
        final trailing? => FadingNavAction(fade: titleFade, child: trailing),
        null => null,
      },
    );
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: floating
              ? FloatingBarFrame(
                  bar: bar,
                  barHeight: bar.preferredSize.height,
                  controller: controller,
                  fade: titleFade,
                  scrollView: (topSpacer) => _scrollView(context, topSpacer),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar,
                    Expanded(child: _scrollView(context, 0)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _scrollView(BuildContext context, double topSpacer) => CustomScrollbar(
    key: GlobalObjectKey(controller),
    controller: controller,
    child: CustomScrollView(
      controller: controller,
      slivers: [
        if (topSpacer > 0)
          SliverToBoxAdapter(child: SizedBox(height: topSpacer)),
        ...FloatingPanels.slivers(context, slivers),
      ],
    ),
  );
}
