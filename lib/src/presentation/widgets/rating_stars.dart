import 'package:flutter/material.dart';

class RatingStars extends StatefulWidget {
  const RatingStars({
    required this.rating,
    this.onChanged,
    this.size = 20,
    this.color,
    this.emptyColor,
    this.spacing = 0,
    super.key,
  });

  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;
  final Color? color;
  final Color? emptyColor;
  final double spacing;

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  int? _hovered;

  void _setHovered(int? value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = widget.color ?? scheme.primary;
    final empty = widget.emptyColor ?? scheme.onPrimary.withValues(alpha: 0.35);
    final hovered = widget.onChanged == null ? null : _hovered;
    final shown = hovered ?? widget.rating;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var value = 1; value <= 5; value++)
          Padding(
            padding: EdgeInsets.only(right: value < 5 ? widget.spacing : 0),
            child: _Star(
              filled: value <= shown,
              size: widget.size,
              color: value > shown
                  ? empty
                  : hovered != null
                  ? filled.withValues(alpha: 0.6)
                  : filled,
              onTap: widget.onChanged == null
                  ? null
                  : () => widget.onChanged!(
                      value == 1 && widget.rating == 1 ? 0 : value,
                    ),
              onHover: (inside) => _setHovered(inside ? value : null),
            ),
          ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.filled,
    required this.size,
    required this.color,
    required this.onTap,
    required this.onHover,
  });

  final bool filled;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.star_rounded : Icons.star_outline_rounded,
      size: size,
      color: color,
    );
    if (onTap == null) return icon;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: icon,
      ),
    );
  }
}
