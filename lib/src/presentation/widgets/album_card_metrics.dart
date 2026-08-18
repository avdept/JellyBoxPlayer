import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';

class AlbumCardMetrics {
  const AlbumCardMetrics._();

  static double maxWidth(DeviceType device) => carouselWidth(device);

  static double width(DeviceType device) => device.isTablet ? 360 : 175;

  static double mainAxisSpacing(DeviceType device) => device.isMobile ? 15 : 24;

  static double crossAxisSpacing(DeviceType device) =>
      device.isMobile ? 8 : (device.isTablet ? 56 : 28);

  static double carouselWidth(DeviceType device) => width(device);

  static double carouselSpacing(DeviceType device) => device.isMobile ? 12 : 20;

  static double carouselHeight(DeviceType device) {
    final cardWidth = carouselWidth(device);
    return height(cardWidth, isTablet: device.isTablet);
  }

  static double height(double width, {required bool isTablet}) =>
      width +
      AlbumView.coverTextSpacing +
      (isTablet ? 24 : 16) * 1.2 +
      (isTablet ? 22 : 14) * 1.2;

  static SliverGridDelegate gridDelegate(DeviceType device) {
    final cardWidth = maxWidth(device);
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: cardWidth,
      mainAxisSpacing: mainAxisSpacing(device),
      crossAxisSpacing: crossAxisSpacing(device),
      childAspectRatio:
          cardWidth / height(cardWidth, isTablet: device.isTablet),
    );
  }
}
