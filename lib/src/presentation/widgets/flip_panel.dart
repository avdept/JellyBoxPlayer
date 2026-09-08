import 'dart:math' as math;

import 'package:flutter/material.dart';

class FlipPanel extends StatelessWidget {
  const FlipPanel({
    required this.showBack,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 400),
    super.key,
  });

  final bool showBack;
  final Widget front;
  final Widget back;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: showBack ? 1 : 0, end: showBack ? 1 : 0),
    duration: duration,
    curve: Curves.easeInOut,
    builder: (context, value, _) {
      final isBack = value >= 0.5;
      final angle = value * math.pi;
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0008)
          ..rotateY(isBack ? angle - math.pi : angle),
        child: isBack ? back : front,
      );
    },
  );
}
