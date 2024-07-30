import 'package:flutter/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class DeviceType {
  DeviceType.fromScreenSize(Size size, [ScreenBreakpoints? breakpoint])
      : screenType = getDeviceType(size, breakpoint),
        screenSize = size;

  final DeviceScreenType screenType;
  final Size screenSize;

  bool get isDesktop => screenType == DeviceScreenType.desktop;
  bool get isTablet => screenType == DeviceScreenType.tablet;
  bool get isMobile => screenType == DeviceScreenType.mobile;
  bool get isWatch => screenType == DeviceScreenType.watch;
}
