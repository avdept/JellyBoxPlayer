import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/presentation/widgets/hover_zoom.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

class HoverIconButton extends ConsumerWidget {
  const HoverIconButton({
    required this.icon,
    required this.onPressed,
    this.selectedIcon,
    this.isSelected,
    this.tooltip,
    this.color,
    this.hoverColor,
    this.mutedHover = false,
    this.selectedColor,
    this.disabledColor,
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
  final bool mutedHover;
  final Color? selectedColor;
  final Color? disabledColor;
  final double? iconSize;
  final ButtonStyle? style;

  static Color muted(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withSaturation(hsl.saturation * 0.5)
        .withLightness(0.55)
        .toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final hover = hoverColor ?? (mutedHover ? muted(accent) : accent);
    return HoverZoom(
      enabled: onPressed != null,
      builder: (context, hovered) => IconButton(
        onPressed: onPressed,
        icon: icon,
        selectedIcon: selectedIcon,
        isSelected: isSelected,
        tooltip: tooltip,
        iconSize: iconSize ?? 20,
        style: ButtonStyle(
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return disabledColor;
            if (states.contains(WidgetState.selected)) {
              return selectedColor ?? accent;
            }
            return hovered ? hover : color;
          }),
        ).merge(style),
      ),
    );
  }
}
