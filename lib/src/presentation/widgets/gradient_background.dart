import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  Widget body(ThemeData theme) => LayoutBuilder(
    builder: (context, constraints) {
      final size = (constraints.maxWidth * 1.4).clamp(900.0, 2400.0);
      final glow = theme.colorScheme.primary;
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -size / 2,
            right: -size / 2,
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glow.withValues(alpha: 0.25),
                    glow.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return body(theme);

    // return Consumer(builder: (context, ref, child) {
    //   final paletteProv = ref.watch(paletteProvider);
    //   return paletteProv.when(
    //     data: (palette) {
    //       final newTheme = theme.copyWith(colorScheme: palette);

    //       return Theme(data: newTheme, child: body(newTheme));
    //     },
    //     loading: () => Theme(data: theme, child: body(theme)),
    //     error: (err, stack) => Theme(data: theme, child: body(theme)),
    //   );
    // },);
  }
}
