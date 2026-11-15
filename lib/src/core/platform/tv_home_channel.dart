import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jplayer/src/core/platform/tv_mode.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/models/models.dart';

abstract final class TvHomeChannel {
  static const _channel = MethodChannel('jellybox/platform');
  static const _coverSize = 400;
  static const albumLimit = 10;

  static String? _published;

  static Future<void> publishRecentlyAdded(
    List<LibraryItem> albums,
    ImageService images,
  ) async {
    if (!TvMode.isTv) return;
    final latest = albums.take(albumLimit).toList();
    final signature = latest.map((album) => album.id).join(',');
    if (signature == _published) return;
    _published = signature;
    try {
      await _channel.invokeMethod<void>('publishHomeChannel', {
        'title': 'Recently added',
        'albums': [
          for (final album in latest)
            {
              'id': album.id,
              'title': album.name,
              'artist': album.albumArtist,
              'cover': await _coverPath(album, images),
            },
        ],
      });
    } on PlatformException catch (error) {
      _published = null;
      debugPrint('[TvHomeChannel] publish failed: $error');
    }
  }

  static Future<void> clear() async {
    if (!TvMode.isTv) return;
    _published = null;
    try {
      await _channel.invokeMethod<void>('clearHomeChannel');
    } on PlatformException catch (error) {
      debugPrint('[TvHomeChannel] clear failed: $error');
    }
  }

  static Future<String?> takePendingAlbum() async {
    if (!TvMode.isTv) return null;
    try {
      return await _channel.invokeMethod<String>('takePendingAlbum');
    } on PlatformException catch (error) {
      debugPrint('[TvHomeChannel] pending album failed: $error');
      return null;
    }
  }

  static void listen(void Function(String albumId) onOpenAlbum) {
    if (!TvMode.isTv) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openAlbum' && call.arguments is String) {
        onOpenAlbum(call.arguments as String);
      }
    });
  }

  static void stopListening() {
    if (TvMode.isTv) _channel.setMethodCallHandler(null);
  }

  static Future<String?> _coverPath(
    LibraryItem album,
    ImageService images,
  ) async {
    final uri = images.itemUri(album, size: _coverSize);
    if (uri == null) return null;
    if (uri.isScheme('file')) return uri.toFilePath();
    if (!uri.isScheme('http') && !uri.isScheme('https')) return null;
    return ArtworkCache.instance.pathFor(uri.toString());
  }
}
