import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';

class TvButton extends StatelessWidget {
  const TvButton({
    required this.label,
    this.icon,
    this.onSelect,
    this.primary = false,
    this.busy = false,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onSelect;

  final bool primary;
  final bool busy;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return TvFocusable(
      onSelect: busy ? null : onSelect,
      autofocus: autofocus,
      focusNode: focusNode,
      enabled: onSelect != null,
      scrollOnFocus: false,
      builder: (context, focused) {
        final background = focused
            ? Colors.white
            : (primary ? accent : Colors.white12);
        final foreground = focused ? Colors.black : Colors.white;
        return AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            boxShadow: focused ? TvTokens.glow(alpha: 0.3) : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 20, color: foreground),
              if (busy || icon != null) const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TvIconButton extends StatelessWidget {
  const TvIconButton({
    required this.icon,
    this.onSelect,
    this.size = 46,
    this.iconSize = 24,
    this.selected = false,
    this.primary = false,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onSelect;
  final double size;
  final double iconSize;

  final bool selected;

  final bool primary;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return TvFocusable(
      onSelect: onSelect,
      autofocus: autofocus,
      focusNode: focusNode,
      enabled: onSelect != null,
      scrollOnFocus: false,
      builder: (context, focused) {
        final background = focused
            ? Colors.white
            : (primary ? accent : Colors.white12);
        final foreground = focused
            ? Colors.black
            : (selected ? accent : Colors.white);
        return AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            boxShadow: focused ? TvTokens.glow(alpha: 0.3) : const [],
          ),
          child: Icon(icon, size: iconSize, color: foreground),
        );
      },
    );
  }
}
