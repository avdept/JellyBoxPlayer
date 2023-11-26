import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';


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
