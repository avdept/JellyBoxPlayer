import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

class FrostedPanel extends ConsumerWidget {
  const FrostedPanel({
    required this.child,
    this.color,
    this.borderRadius = BorderRadius.zero,
    this.blur = 24,
    this.elevation = 0,
    super.key,
  });

  final Widget child;
  final Color? color;
  final BorderRadius borderRadius;
  final double blur;
  final double elevation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tint =
        color ??
        (ref.watch(artworkSchemeProvider).valueOrNull?.surface ??
                theme.bottomSheetTheme.backgroundColor ??
                Colors.black)
            .withValues(alpha: 0.88);

    return Material(
      color: tint,
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
}
