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

Future<WidgetArtwork?> loadWidgetArtwork(MediaItem item) async {
  final uri = item.artUri;
  if (uri == null) return null;
  final path = uri.isScheme('file')
      ? uri.toFilePath()
      : await ArtworkCache.instance.pathFor(uri.toString());
  if (path == null) return null;

  final png = await _downscale(await File(path).readAsBytes());
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

Future<Uint8List> _downscale(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final wide = descriptor.width >= descriptor.height;
  final fits =
      descriptor.width <= widgetCoverSize &&
      descriptor.height <= widgetCoverSize;
  final codec = await descriptor.instantiateCodec(
    targetWidth: fits || !wide ? null : widgetCoverSize,
    targetHeight: fits || wide ? null : widgetCoverSize,
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
