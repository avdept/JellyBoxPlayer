import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FlipSide { front, left, right }

class FlipPanel extends StatelessWidget {
  const FlipPanel({
    required this.side,
    required this.front,
    this.left,
    this.right,
    this.duration = const Duration(milliseconds: 400),
    super.key,
  });

  final FlipSide side;
  final Widget front;
  final Widget? left;
  final Widget? right;
  final Duration duration;

  double get _turn => switch (side) {
    FlipSide.front => 0,
    FlipSide.left => -1,
    FlipSide.right => 1,
  };

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: _turn, end: _turn),
    duration: duration,
    curve: Curves.easeInOut,
    builder: (context, value, _) {
      final showFront = value.abs() < 0.5;
      final angle = value * math.pi;
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0008)
          ..rotateY(showFront ? angle : angle - math.pi * value.sign),
        child: showFront ? front : ((value > 0 ? right : left) ?? front),
      );
    },
  );
}
