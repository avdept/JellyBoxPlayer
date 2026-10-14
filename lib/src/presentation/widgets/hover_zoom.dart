import 'package:flutter/material.dart';

class HoverZoom extends StatefulWidget {
  const HoverZoom({
    required this.builder,
    this.enabled = true,
    this.scale = 1.12,
    this.pressedScale = 0.95,
    super.key,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final bool enabled;
  final double scale;
  final double pressedScale;

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

  double get _scale {
    if (!widget.enabled) return 1;
    if (_pressed) return widget.pressedScale;
    return _hovered ? widget.scale : 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            ),
            child: Builder(
              builder: (context) =>
                  widget.builder(context, widget.enabled && _hovered),
            ),
          ),
        ),
      ),
    );
  }
}
