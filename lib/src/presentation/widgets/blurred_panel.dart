import 'dart:ui';

import 'package:flutter/material.dart';

class BlurredPanel extends StatelessWidget {
  const BlurredPanel({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor.withOpacity(0.9),
                theme.scaffoldBackgroundColor.withOpacity(0),
              ],
              stops: const [0.1, 1],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
