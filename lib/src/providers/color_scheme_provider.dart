import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
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

final currentArtUriProvider = Provider<Uri?>(
  (ref) => ref.watch(nowPlayingProvider)?.artUri,
);

final artworkSchemeProvider = FutureProvider<ColorScheme?>((ref) async {
  final artUri = ref.watch(currentArtUriProvider);
  if (artUri == null) return null;
  return ColorScheme.fromImageProvider(
    provider: ref.read(imageServiceProvider).artworkImage(artUri),
    brightness: Brightness.dark,
  );
});
