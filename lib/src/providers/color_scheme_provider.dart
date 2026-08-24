import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

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

final currentArtUriProvider = StreamProvider<Uri?>(
  (ref) => ref
      .watch(playerProvider)
      .sequenceStateStream
      .map((state) => (state.currentSource?.tag as MediaItem?)?.artUri),
);

final artworkSchemeProvider = FutureProvider<ColorScheme?>((ref) async {
  final artUri = ref.watch(currentArtUriProvider).valueOrNull;
  if (artUri == null) return null;
  return ColorScheme.fromImageProvider(
    provider: ref.read(imageServiceProvider).artworkImage(artUri),
    brightness: Brightness.dark,
  );
});
