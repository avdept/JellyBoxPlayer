import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  Widget body(ThemeData theme) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -325,
            right: -450,
            width: 1000,
            height: 1000,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
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
