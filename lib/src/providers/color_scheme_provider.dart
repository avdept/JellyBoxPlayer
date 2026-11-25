import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:palette_generator/palette_generator.dart';

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
          brightness: AppColors.of(ref.watch(colorThemeProvider)).brightness,
        );
      } on Object {
        return null;
      }
    });

final AutoDisposeFutureProvider<PaletteGenerator?> artworkPaletteProvider =
    FutureProvider.autoDispose<PaletteGenerator?>((ref) async {
      final artUri = ref.watch(currentArtUriProvider);
      if (artUri == null) return null;
      try {
        return await PaletteGenerator.fromImageProvider(
          ref.read(imageServiceProvider).artworkImage(artUri),
          size: const Size(128, 128),
          maximumColorCount: 12,
        );
      } on Object {
        return null;
      }
    });

final AutoDisposeProvider<Color> accentColorProvider = Provider.autoDispose(
  (ref) {
    final appAccent = AppColors.of(ref.watch(colorThemeProvider)).primary;
    if (!ref.watch(settingProvider(AppSetting.artworkAccent))) return appAccent;
    return ref.watch(artworkSchemeProvider).valueOrNull?.primary ?? appAccent;
  },
);

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

final AutoDisposeFutureProviderFamily<Color?, Uri> artworkEdgeColorProvider =
    FutureProvider.autoDispose.family<Color?, Uri>((
      ref,
      uri,
    ) async {
      try {
        return await bottomEdgeColor(
          ref.read(imageServiceProvider).artworkImage(uri),
        );
      } on Object {
        return null;
      }
    });

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

final AutoDisposeFutureProviderFamily<ColorScheme?, LibraryItem>
itemCoverSchemeProvider = FutureProvider.autoDispose
    .family<ColorScheme?, LibraryItem>((ref, item) async {
      final cached = _coverSchemes[item.id];
      if (cached != null) return cached;
      try {
        final provider = ref.read(imageServiceProvider).itemImage(item);
        final seed = await _serialSeed(() => _coverSeed(provider));
        if (seed == null) return null;
        final scheme = ColorScheme.fromSeed(
          seedColor: Color(seed),
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        );
        _coverSchemes[item.id] = scheme;
        if (_coverSchemes.length > _coverSchemeLimit) {
          _coverSchemes.remove(_coverSchemes.keys.first);
        }
        return scheme;
      } on Object {
        return null;
      }
    });

const _coverSchemeLimit = 300;
const _seedSampleSize = 64;
final _coverSchemes = <String, ColorScheme>{};
Future<void> _seedQueue = Future.value();

Future<T> _serialSeed<T>(Future<T> Function() task) {
  final result = _seedQueue.then((_) => task());
  _seedQueue = result.then<void>((_) {}, onError: (Object _) {});
  return result;
}

Future<int?> _coverSeed(ImageProvider provider) async {
  final image = await _decodeImage(
    ResizeImage(
      provider,
      width: _seedSampleSize,
      height: _seedSampleSize,
      policy: ResizeImagePolicy.fit,
    ),
  );
  final ByteData? bytes;
  try {
    bytes = await image.toByteData();
  } finally {
    image.dispose();
  }
  if (bytes == null) return null;
  final pixels = bytes.buffer.asUint32List();
  return Isolate.run(() => _seedFromPixels(pixels));
}

Future<ui.Image> _decodeImage(ImageProvider provider) {
  final completer = Completer<ui.Image>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      completer.complete(info.image);
    },
    onError: (error, stackTrace) {
      stream.removeListener(listener);
      completer.completeError(error, stackTrace);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

Future<int?> _seedFromPixels(Uint32List abgrPixels) async {
  final result = await QuantizerCelebi().quantize(abgrPixels, 128);
  final colorToCount = result.colorToCount.map(
    (abgr, count) => MapEntry(
      (abgr & 0xFF00FF00) | ((abgr & 0xFF) << 16) | ((abgr >> 16) & 0xFF),
      count,
    ),
  );
  final scored = Score.score(colorToCount, desired: 1);
  return scored.isEmpty ? null : scored.first;
}

final AutoDisposeFutureProviderFamily<Color?, LibraryItem>
itemGlowColorProvider = FutureProvider.autoDispose.family<Color?, LibraryItem>(
  (ref, item) async =>
      (await ref.watch(itemCoverSchemeProvider(item).future))?.primary,
);
