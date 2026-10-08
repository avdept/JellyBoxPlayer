import 'package:flutter/material.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/pages/album/desktop/desktop_album_page.dart';
import 'package:jplayer/src/presentation/pages/album/mobile/mobile_album_page.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class AlbumPageKeys {
  const AlbumPageKeys({
    required this.downloadButton,
    required this.deleteButton,
    required this.confirmationDialog,
  });

  final Key downloadButton;
  final Key deleteButton;
  final Key confirmationDialog;
}

class AlbumPage extends StatelessWidget {
  const AlbumPage({
    required this.album,
    @visibleForTesting this.testKeys,
    super.key,
  });

  final LibraryItem album;
  final AlbumPageKeys? testKeys;

  @override
  Widget build(BuildContext context) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    if (device.isMobile) {
      return MobileAlbumPage(album: album, testKeys: testKeys);
    }
    return DesktopAlbumPage(album: album, testKeys: testKeys);
  }
}
