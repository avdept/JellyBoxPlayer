import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FloatingPanels extends InheritedWidget {
  const FloatingPanels({required super.child, super.key});

  static const margin = 10.0;
  static const playerHeight = 72.0;
  static const panelAlpha = 0.72;
  static const blurSigma = 24.0;
  static const radius = BorderRadius.all(Radius.circular(18));

  static bool enabled(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FloatingPanels>() != null;

  @override
  bool updateShouldNotify(FloatingPanels oldWidget) => false;
}

class FloatingPanel extends StatelessWidget {
  const FloatingPanel({
    required this.child,
    this.clip = true,
    this.visible = true,
    super.key,
  });

  static const _shadow = [
    BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  final Widget child;
  final bool clip;
  final bool visible;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      borderRadius: FloatingPanels.radius,
      border: visible
          ? Border.all(color: Colors.white.withValues(alpha: 0.06))
          : null,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: FloatingPanels.radius,
        boxShadow: visible ? _shadow : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: FloatingPanels.radius,
              child: BackdropFilter(
                enabled: visible,
                filter: ImageFilter.blur(
                  sigmaX: FloatingPanels.blurSigma,
                  sigmaY: FloatingPanels.blurSigma,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          if (clip)
            ClipRRect(borderRadius: FloatingPanels.radius, child: child)
          else
            child,
        ],
      ),
    ),
  );
}

class SizeReporter extends SingleChildRenderObjectWidget {
  const SizeReporter({
    required this.onSize,
    required super.child,
    super.key,
  });

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class RenderSizeReporter extends RenderProxyBox {
  RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final current = size;
    if (current == _reported) return;
    _reported = current;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(current));
  }
}
