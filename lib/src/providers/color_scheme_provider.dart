import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

// Example image provider - this could be any provider that supplies an image
final imageSchemeProvider = StateProvider<ImageProvider>((ref) {
  return const AssetImage(Images.coverSample);
});

// Palette generator provider
final paletteProvider = FutureProvider<ColorScheme>((ref) async {
  final image = ref.watch(imageSchemeProvider);
  return ColorScheme.fromImageProvider(
    provider: image,
    brightness: Brightness.dark,
  );
});

final AutoDisposeProvider<Uri?> currentArtUriProvider = Provider.autoDispose(
  (ref) => ref.watch(barMediaItemProvider)?.artUri,
);

final AutoDisposeFutureProvider<ColorScheme?> artworkSchemeProvider =
    FutureProvider.autoDispose<ColorScheme?>((ref) async {
      final artUri = ref.watch(currentArtUriProvider);
      if (artUri == null) return null;
      try {
        return await ColorScheme.fromImageProvider(
          provider: ref.read(imageServiceProvider).artworkImage(artUri),
          brightness: Brightness.dark,
        );
      } on Object {
        return null;
      }
    });

final AutoDisposeFutureProviderFamily<Color?, LibraryItem>
coverEdgeColorProvider = FutureProvider.autoDispose.family<Color?, LibraryItem>(
  (ref, item) async {
    try {
      return await bottomEdgeColor(
        ref.read(imageServiceProvider).itemImage(item),
      );
    } on Object {
      return null;
    }
  },
);

Future<Color?> bottomEdgeColor(
  ImageProvider provider, {
  double fraction = 0.15,
}) async {
  final stream = ResizeImage(
    provider,
    width: 48,
  ).resolve(ImageConfiguration.empty);
  final completer = Completer<ImageInfo>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(info);
    },
    onError: (error, stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    },
  );
  stream.addListener(listener);
  final info = await completer.future;
  try {
    return averageOfBottomRows(
      await info.image.toByteData(),
      width: info.image.width,
      height: info.image.height,
      fraction: fraction,
    );
  } finally {
    info.dispose();
  }
}

Color? averageOfBottomRows(
  ByteData? rgba, {
  required int width,
  required int height,
  required double fraction,
}) {
  if (rgba == null || width == 0 || height == 0) return null;
  final start = (height * (1 - fraction)).floor().clamp(0, height - 1);
  var r = 0;
  var g = 0;
  var b = 0;
  var count = 0;
  for (var y = start; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      r += rgba.getUint8(i);
      g += rgba.getUint8(i + 1);
      b += rgba.getUint8(i + 2);
      count++;
    }
  }
  if (count == 0) return null;
  return Color.fromARGB(255, r ~/ count, g ~/ count, b ~/ count);
}

final AutoDisposeFutureProviderFamily<Color?, LibraryItem>
itemGlowColorProvider = FutureProvider.autoDispose.family<Color?, LibraryItem>((
  ref,
  item,
) async {
  try {
    final scheme = await ColorScheme.fromImageProvider(
      provider: ref.read(imageServiceProvider).itemImage(item),
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );
    return scheme.primary;
  } on Object {
    return null;
  }
});
