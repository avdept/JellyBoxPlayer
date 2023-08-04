import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:jplayer/src/config/constants.dart';

extension AdaptiveContext on BuildContext {
  bool get isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  bool get isTablet =>
      (Platform.isIOS || Platform.isAndroid || Platform.isFuchsia) &&
      MediaQuery.sizeOf(this).shortestSide >= kTabletBreakpoint;

  bool get isMobile =>
      (Platform.isIOS || Platform.isAndroid || Platform.isFuchsia) &&
      MediaQuery.sizeOf(this).shortestSide < kTabletBreakpoint;
}
