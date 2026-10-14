import 'package:flutter/material.dart';

class HoverZoom extends StatefulWidget {
  const HoverZoom({
    required this.builder,
    this.color,
    this.scale = 1.12,
    this.pressedScale = 0.9,
    super.key,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final Color? color;
  final double scale;
  final double pressedScale;

  static Color mutedAccent(BuildContext context) {
    final accent = HSLColor.fromColor(Theme.of(context).colorScheme.primary);
    return accent
        .withSaturation(accent.saturation * 0.5)
        .withLightness(0.55)
        .toColor();
  }

  @override
  State<HoverZoom> createState() => _HoverZoomState();
}

class _HoverZoomState extends State<HoverZoom> {
  var _hovered = false;
  var _pressed = false;

  void _setHovered(bool hovered) {
    if (hovered != _hovered) setState(() => _hovered = hovered);
  }

  void _setPressed(bool pressed) {
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  double get _scale => _pressed
      ? widget.pressedScale
      : _hovered
      ? widget.scale
      : 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.color ?? theme.colorScheme.primary;
    final iconButtonStyle = ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: _hovered ? WidgetStatePropertyAll(accent) : null,
    ).merge(theme.iconButtonTheme.style);

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Theme(
            data: theme.copyWith(
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              iconButtonTheme: IconButtonThemeData(style: iconButtonStyle),
            ),
            child: Builder(
              builder: (context) => widget.builder(context, _hovered),
            ),
          ),
        ),
      ),
    );
  }
}
