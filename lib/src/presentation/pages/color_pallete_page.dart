import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:palette_generator/palette_generator.dart';

const Color _kBackgroundColor = Color(0xffa0a0a0);
const Color _kPlaceholderColor = Color(0x80404040);

class ColorPalettePage extends StatefulWidget {
  const ColorPalettePage({super.key});

  @override
  State<ColorPalettePage> createState() => _ColorPalettePageState();
}

class _ColorPalettePageState extends State<ColorPalettePage> {
  PaletteGenerator? paletteGenerator;
  ColorScheme? colorScheme;

  late ImageProvider imageProvider;

  Future<void> _updatePaletteGenerator() async {
    paletteGenerator = await PaletteGenerator.fromImageProvider(
      imageProvider,
    );
    colorScheme = await ColorScheme.fromImageProvider(
      provider: imageProvider,
      brightness: Brightness.dark,
    );
    // setState(() {});
  }

  @override
  void initState() {
    super.initState();
    imageProvider = const AssetImage(Images.coverSample);
    _updatePaletteGenerator();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Image(
                image: imageProvider,
                height: 200,
                fit: BoxFit.fitHeight,
              ),
            ),
            Expanded(
              child: PaletteSwatches(
                generator: paletteGenerator,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaletteSwatches extends StatelessWidget {
  const PaletteSwatches({
    super.key,
    this.generator,
    this.colorScheme,
  });

  final PaletteGenerator? generator;
  final ColorScheme? colorScheme;

  @override
  Widget build(BuildContext context) {
    final paletteGen = generator;

    if (paletteGen == null || paletteGen.colors.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorPaletteColors = {
      'Dominant': paletteGen.dominantColor,
      'Light Vibrant': paletteGen.lightVibrantColor,
      'Vibrant': paletteGen.vibrantColor,
      'Dark Vibrant': paletteGen.darkVibrantColor,
      'Light Muted': paletteGen.lightMutedColor,
      'Muted': paletteGen.mutedColor,
      'Dark Muted': paletteGen.darkMutedColor,
    };

    final colorSchemeColors = {
      'primary': colorScheme?.primary,
      'onPrimary': colorScheme?.onPrimary,
      'primaryContainer': colorScheme?.primaryContainer,
      'onPrimaryContainer': colorScheme?.onPrimaryContainer,
      'secondary': colorScheme?.secondary,
      'onSecondary': colorScheme?.onSecondary,
      'secondaryContainer': colorScheme?.secondaryContainer,
      'onSecondaryContainer': colorScheme?.onSecondaryContainer,
      'tertiary': colorScheme?.tertiary,
      'onTertiary': colorScheme?.onTertiary,
      'tertiaryContainer': colorScheme?.tertiaryContainer,
      'onTertiaryContainer': colorScheme?.onTertiaryContainer,
      'error': colorScheme?.error,
      'onError': colorScheme?.onError,
      'errorContainer': colorScheme?.errorContainer,
      'onErrorContainer': colorScheme?.onErrorContainer,
      'outline': colorScheme?.outline,
      'outlineVariant': colorScheme?.outlineVariant,
      'background': colorScheme?.background,
      'onBackground': colorScheme?.onBackground,
      'surface': colorScheme?.surface,
      'onSurface': colorScheme?.onSurface,
      'surfaceVariant': colorScheme?.surfaceVariant,
      'onSurfaceVariant': colorScheme?.onSurfaceVariant,
      'inverseSurface': colorScheme?.inverseSurface,
      'onInverseSurface': colorScheme?.onInverseSurface,
      'inversePrimary': colorScheme?.inversePrimary,
      'shadow': colorScheme?.shadow,
      'scrim': colorScheme?.scrim,
      'surfaceTint': colorScheme?.surfaceTint,
    };

    const columnLength = 10;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Palette generator:'),
        const SizedBox(height: 6),
        Wrap(
          children: paletteGen.colors
              .map((color) => PaletteSwatch(color: color))
              .toList(growable: false),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: List.generate(
                colorPaletteColors.length,
                (index) => PaletteSwatch(
                  label: colorPaletteColors.keys.elementAt(index),
                  color: colorPaletteColors.values.elementAt(index)?.color,
                ),
              ),
            ),
            Column(
              children: List.generate(
                colorPaletteColors.length,
                (index) => PaletteSwatch(
                  label: 'titleText',
                  color: colorPaletteColors.values
                      .elementAt(index)
                      ?.titleTextColor,
                ),
              ),
            ),
            Column(
              children: List.generate(
                colorPaletteColors.length,
                (index) => PaletteSwatch(
                  label: 'bodyText',
                  color:
                      colorPaletteColors.values.elementAt(index)?.bodyTextColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text('Color scheme:'),
        const SizedBox(height: 6),
        Wrap(
          children: List.generate(
            colorSchemeColors.length,
            (index) => PaletteSwatch(
              color: colorSchemeColors.values.elementAt(index),
              child: Text(index.toString()),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Row(
            children: List.generate(
              (colorSchemeColors.entries.length / columnLength).floor(),
              (i) {
                final items = colorSchemeColors.entries
                    .skip(i * columnLength)
                    .take(columnLength);

                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      items.length,
                      (j) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PaletteSwatch(
                            color: items.elementAt(j).value,
                            child: Text((i * columnLength + j).toString()),
                          ),
                          const SizedBox(width: 8),
                          Text(items.elementAt(j).key),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({
    super.key,
    this.color,
    this.label,
    this.child,
  });

  final Color? color;
  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // Compute the "distance" of the color swatch and the background color
    // so that we can put a border around those color swatches that are too
    // close to the background's saturation and lightness. We ignore hue for
    // the comparison.
    final hslColor = HSLColor.fromColor(color ?? Colors.transparent);
    final backgroundAsHsl = HSLColor.fromColor(_kBackgroundColor);
    final colorDistance = sqrt(
      pow(hslColor.saturation - backgroundAsHsl.saturation, 2.0) +
          pow(hslColor.lightness - backgroundAsHsl.lightness, 2.0),
    );

    Widget swatch = Padding(
      padding: const EdgeInsets.all(2),
      child: color == null
          ? Placeholder(
              fallbackWidth: 30,
              fallbackHeight: 20,
              color: const Color(0xff404040),
              child: child,
            )
          : Container(
              decoration: BoxDecoration(
                color: color,
                border: Border.all(
                  color: _kPlaceholderColor,
                  style: colorDistance < 0.2
                      ? BorderStyle.solid
                      : BorderStyle.none,
                ),
              ),
              width: 30,
              height: 20,
              child: child,
            ),
    );

    if (label != null) {
      swatch = ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 130),
        child: Row(
          children: [
            swatch,
            const SizedBox(width: 5),
            Text(label!),
          ],
        ),
      );
    }
    return swatch;
  }
}
