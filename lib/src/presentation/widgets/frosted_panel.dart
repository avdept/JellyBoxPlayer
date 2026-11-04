import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

class FrostedPanel extends ConsumerWidget {
  const FrostedPanel({
    required this.child,
    this.color,
    this.scrim,
    this.borderRadius = BorderRadius.zero,
    this.blur = 24,
    this.elevation = 0,
    super.key,
  });

  static const Color sidebarScrim = Colors.black54;

  final Widget child;
  final Color? color;
  final Color? scrim;
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
    final scrim = this.scrim;

    return Material(
      color: scrim == null ? tint : Color.alphaBlend(tint, scrim),
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
