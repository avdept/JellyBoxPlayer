import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/window/mac_title_bar.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';

enum FloatingMode { off, framed, overlay }

class FloatingPanels extends InheritedWidget {
  const FloatingPanels({
    required this.radius,
    required super.child,
    this.shadow = PanelShadow.normal,
    this.contentInsets = EdgeInsets.zero,
    this.translucent = true,
    this.overlay = false,
    super.key,
  });

  static const margin = 10.0;
  static const playerHeight = 72.0;
  static const panelAlpha = 0.72;
  static const blurSigma = 24.0;

  static double get maxRadius =>
      math.max(0, (MacTitleBar.windowCornerRadius ?? 28) - margin);

  final double radius;
  final PanelShadow shadow;
  final EdgeInsets contentInsets;
  final bool translucent;
  final bool overlay;

  static bool overlayOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FloatingPanels>()?.overlay ??
      false;

  static bool translucentOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FloatingPanels>()
          ?.translucent ??
      true;

  static bool enabled(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FloatingPanels>() != null;

  static FloatingMode modeOf(BuildContext context) =>
      switch (context.dependOnInheritedWidgetOfExactType<FloatingPanels>()) {
        null => FloatingMode.off,
        FloatingPanels(overlay: true) => FloatingMode.overlay,
        _ => FloatingMode.framed,
      };

  static double barHeightOf(BuildContext context, double regular) =>
      enabled(context) ? 52 : regular;

  static double barPaddingOf(BuildContext context, double regular) =>
      enabled(context) ? 8 : regular;

  static Color fill(BuildContext context, {required bool translucent}) =>
      AppColors.from(
        context,
      ).panel.withValues(alpha: translucent ? panelAlpha : 1);

  static Color fillOf(BuildContext context) =>
      fill(context, translucent: translucentOf(context));

  static EdgeInsets contentInsetsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FloatingPanels>()
          ?.contentInsets ??
      EdgeInsets.zero;

  static List<Widget> slivers(BuildContext context, List<Widget> slivers) {
    final insets = contentInsetsOf(context);
    if (insets == EdgeInsets.zero) return slivers;
    return [
      for (final sliver in slivers)
        SliverPadding(
          padding: EdgeInsets.only(left: insets.left),
          sliver: sliver,
        ),
      SliverToBoxAdapter(child: SizedBox(height: insets.bottom)),
    ];
  }

  static BorderRadius radiusOf(BuildContext context) => BorderRadius.circular(
    math.min(
      context.dependOnInheritedWidgetOfExactType<FloatingPanels>()?.radius ?? 0,
      maxRadius,
    ),
  );

  static List<BoxShadow> shadowOf(BuildContext context) => switch (context
      .dependOnInheritedWidgetOfExactType<FloatingPanels>()
      ?.shadow) {
    PanelShadow.normal || null => const [
      BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    PanelShadow.min => const [
      BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
    ],
    PanelShadow.none => const [],
  };

  @override
  bool updateShouldNotify(FloatingPanels oldWidget) =>
      radius != oldWidget.radius ||
      shadow != oldWidget.shadow ||
      contentInsets != oldWidget.contentInsets ||
      translucent != oldWidget.translucent ||
      overlay != oldWidget.overlay;
}

class FloatingInset extends StatelessWidget {
  const FloatingInset({required this.child, this.bottom = false, super.key});

  final Widget child;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final insets = FloatingPanels.contentInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(
        left: insets.left,
        bottom: bottom ? insets.bottom : 0,
      ),
      child: child,
    );
  }
}

class FloatingPanel extends StatelessWidget {
  const FloatingPanel({
    required this.child,
    this.clip = true,
    this.visible = true,
    this.alwaysBlur = false,
    super.key,
  });

  final Widget child;
  final bool clip;
  final bool visible;
  final bool alwaysBlur;

  @override
  Widget build(BuildContext context) {
    final radius = FloatingPanels.radiusOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: visible ? FloatingPanels.shadowOf(context) : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                enabled:
                    visible &&
                    FloatingPanels.translucentOf(context) &&
                    (alwaysBlur || FloatingPanels.overlayOf(context)),
                filter: ImageFilter.blur(
                  sigmaX: FloatingPanels.blurSigma,
                  sigmaY: FloatingPanels.blurSigma,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          if (clip) ClipRRect(borderRadius: radius, child: child) else child,
        ],
      ),
    );
  }
}

class ScrollFadingPanel extends StatelessWidget {
  const ScrollFadingPanel({required this.controller, this.fade, super.key});

  static const fadeDistance = 48.0;

  final ScrollController controller;
  final ValueListenable<double>? fade;

  double get _opacity =>
      fade?.value ??
      (controller.hasClients
          ? (controller.offset / fadeDistance).clamp(0.0, 1.0)
          : 0.0);

  @override
  Widget build(BuildContext context) {
    final fill = ColoredBox(
      color: FloatingPanels.fillOf(context),
      child: const SizedBox.expand(),
    );
    return ListenableBuilder(
      listenable: fade ?? controller,
      builder: (context, _) {
        final opacity = _opacity;
        return Opacity(
          opacity: opacity,
          child: FloatingPanel(
            visible: opacity > 0,
            alwaysBlur: true,
            child: fill,
          ),
        );
      },
    );
  }
}

class FloatingBarFrame extends StatelessWidget {
  const FloatingBarFrame({
    required this.bar,
    required this.barHeight,
    required this.controller,
    required this.scrollView,
    this.fade,
    this.background,
    super.key,
  });

  final Widget bar;
  final double barHeight;
  final ScrollController controller;
  final ValueListenable<double>? fade;
  final Widget? background;
  final Widget Function(double topSpacer) scrollView;

  static double scrollInsetOf(BuildContext context, double barHeight) =>
      switch (FloatingPanels.modeOf(context)) {
        FloatingMode.off => barHeight,
        FloatingMode.framed => 0,
        FloatingMode.overlay => barHeight + FloatingPanels.margin,
      };

  static double contentTopOf(BuildContext context, double barHeight) =>
      MediaQuery.paddingOf(context).top +
      switch (FloatingPanels.modeOf(context)) {
        FloatingMode.off => barHeight,
        FloatingMode.framed => barHeight + FloatingPanels.margin * 2,
        FloatingMode.overlay => barHeight + FloatingPanels.margin,
      };

  @override
  Widget build(BuildContext context) {
    const margin = FloatingPanels.margin;
    final barTop = MediaQuery.paddingOf(context).top + margin;
    return Stack(
      children: [
        ?background,
        if (FloatingPanels.modeOf(context) == FloatingMode.framed)
          Positioned(
            left: 0,
            top: barTop + barHeight + margin,
            right: 0,
            bottom: 0,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: scrollView(0),
            ),
          )
        else
          scrollView(barHeight + margin),
        Positioned(
          left: FloatingPanels.contentInsetsOf(context).left,
          top: barTop,
          right: margin,
          height: barHeight,
          child: RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ScrollFadingPanel(controller: controller, fade: fade),
                ),
                bar,
              ],
            ),
          ),
        ),
      ],
    );
  }
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
