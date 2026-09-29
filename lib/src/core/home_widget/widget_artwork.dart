import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:just_audio_background/just_audio_background.dart'
    show MediaItem;

class WidgetArtwork {
  const WidgetArtwork({
    required this.png,
    required this.background,
    required this.foreground,
  });

  final Uint8List png;
  final Color background;
  final Color foreground;
}

const widgetCoverSize = 400;
const widgetThumbnailSize = 200;

Future<WidgetArtwork?> loadWidgetArtwork(MediaItem item) async {
  final uri = item.artUri;
  if (uri == null) return null;
  final path = uri.isScheme('file')
      ? uri.toFilePath()
      : await ArtworkCache.instance.pathFor(uri.toString());
  if (path == null) return null;

  final png = await _downscale(await File(path).readAsBytes(), widgetCoverSize);
  final scheme = await ColorScheme.fromImageProvider(
    provider: MemoryImage(png),
    brightness: Brightness.dark,
  );
  return WidgetArtwork(
    png: png,
    background: scheme.primaryContainer,
    foreground: scheme.onPrimaryContainer,
  );
}

Future<Uint8List?> loadWidgetThumbnail(Uri? uri) async {
  if (uri == null) return null;
  final path = uri.isScheme('file')
      ? uri.toFilePath()
      : await ArtworkCache.instance.pathFor(uri.toString());
  if (path == null) return null;
  return _downscale(await File(path).readAsBytes(), widgetThumbnailSize);
}

Future<Uint8List> _downscale(Uint8List bytes, int size) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final wide = descriptor.width >= descriptor.height;
  final fits = descriptor.width <= size && descriptor.height <= size;
  final codec = await descriptor.instantiateCodec(
    targetWidth: fits || !wide ? null : size,
    targetHeight: fits || wide ? null : size,
  );
  try {
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    return data!.buffer.asUint8List();
  } finally {
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
}
