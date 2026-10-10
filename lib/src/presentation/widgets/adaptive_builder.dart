import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/core/enums/layout.dart';
import 'package:jplayer/src/core/platform/tv_mode.dart';

export 'package:jplayer/src/core/enums/layout.dart';

class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({
    required this.builder,
    super.key,
  });

  final Widget Function(BuildContext context, Layout layout) builder;

  @override
  Widget build(BuildContext context) {
    if (TvMode.isTv) return builder(context, Layout.tv);
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return builder(context, Layout.desktop);
    }

    final screenSize = MediaQuery.sizeOf(context);

    return builder(
      context,
      (screenSize.shortestSide < kTabletBreakpoint)
          ? Layout.mobile
          : Layout.tablet,
    );
  }
}
