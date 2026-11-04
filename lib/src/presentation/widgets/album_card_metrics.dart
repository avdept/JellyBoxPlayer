import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';

class AlbumCardMetrics {
  const AlbumCardMetrics._();

  static double maxWidth(DeviceType device) => carouselWidth(device);

  static double width(DeviceType device) => 175;

  static double mainAxisSpacing(DeviceType device) => device.isMobile ? 15 : 24;

  static double crossAxisSpacing(DeviceType device) => device.isMobile ? 8 : 28;

  static double carouselWidth(DeviceType device) => width(device);

  static double carouselSpacing(DeviceType device) => device.isMobile ? 12 : 20;

  static double carouselHeight(DeviceType device) =>
      height(carouselWidth(device));

  static double height(double width) =>
      width +
      AlbumView.coverTextSpacing +
      AlbumView.titleFontSize * 1.2 +
      AlbumView.subtitleFontSize * 1.2;

  static SliverGridDelegate gridDelegate(DeviceType device) {
    final cardWidth = maxWidth(device);
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: cardWidth,
      mainAxisSpacing: mainAxisSpacing(device),
      crossAxisSpacing: crossAxisSpacing(device),
      childAspectRatio: cardWidth / height(cardWidth),
    );
  }
}
