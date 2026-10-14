import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/hover_zoom.dart';

class HoverIconButton extends StatelessWidget {
  const HoverIconButton({
    required this.icon,
    required this.onPressed,
    this.selectedIcon,
    this.isSelected,
    this.tooltip,
    this.color,
    this.hoverColor,
    this.iconSize,
    this.style,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final Widget? selectedIcon;
  final bool? isSelected;
  final String? tooltip;
  final Color? color;
  final Color? hoverColor;
  final double? iconSize;
  final ButtonStyle? style;

  static Color mutedAccent(BuildContext context) {
    final accent = HSLColor.fromColor(Theme.of(context).colorScheme.primary);
    return accent
        .withSaturation(accent.saturation * 0.5)
        .withLightness(0.55)
        .toColor();
  }

  @override
  Widget build(BuildContext context) => HoverZoom(
    enabled: onPressed != null,
    builder: (context, hovered) {
      final accent = hoverColor ?? Theme.of(context).colorScheme.primary;
      final foreground = hovered ? accent : color;
      return IconButton(
        onPressed: onPressed,
        icon: icon,
        selectedIcon: selectedIcon,
        isSelected: isSelected,
        tooltip: tooltip,
        iconSize: iconSize ?? 20,
        style: ButtonStyle(
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? null : foreground,
          ),
        ).merge(style),
      );
    },
  );
}
