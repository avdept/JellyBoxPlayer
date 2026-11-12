import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';

class HoverTextButton extends StatefulWidget {
  const HoverTextButton({
    required this.label,
    required this.onPressed,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  State<HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<HoverTextButton> {
  var _hovered = false;

  void _setHovered(bool hovered) {
    if (hovered != _hovered) setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Themes.red.colorScheme.primary;
    return MouseRegion(
      cursor: widget.onPressed == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Padding(
          padding: widget.padding,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              color: _hovered ? accent : theme.colorScheme.onPrimary,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
