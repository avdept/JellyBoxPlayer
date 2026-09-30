import 'package:flutter/material.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class WidgetArtwork {
  const WidgetArtwork({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

typedef ArtworkResizer =
    Future<List<int>?> Function({
      required String source,
      required String target,
      required int size,
    });

const widgetCoverSize = 400;
const widgetThumbnailSize = 200;

Future<String?> widgetArtworkSource(Uri? uri) async {
  if (uri == null) return null;
  if (uri.isScheme('file')) return uri.toFilePath();
  return ArtworkCache.instance.pathFor(uri.toString());
}

Future<WidgetArtwork?> widgetArtworkColors(List<int> pixels) async {
  if (pixels.isEmpty) return null;
  final quantized = await QuantizerCelebi().quantize(
    [for (final pixel in pixels) pixel & 0xFFFFFFFF],
    128,
  );
  final seed = Score.score(quantized.colorToCount, desired: 1).first;
  final scheme = ColorScheme.fromSeed(
    seedColor: Color(seed),
    brightness: Brightness.dark,
  );
  return WidgetArtwork(
    background: scheme.primaryContainer,
    foreground: scheme.onPrimaryContainer,
  );
}
