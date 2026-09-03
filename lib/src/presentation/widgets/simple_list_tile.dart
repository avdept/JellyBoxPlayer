import 'package:flutter/material.dart';

const _defaultGap = 8.0;

class SimpleListTile extends StatefulWidget {
  const SimpleListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.leadingToTitle = _defaultGap,
    this.backgroundColor,
    this.hoverColor,
    this.padding = EdgeInsets.zero,
    this.onTap,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final double leadingToTitle;
  final Color? backgroundColor;
  final Color? hoverColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<SimpleListTile> createState() => _SimpleListTileState();
}

class _SimpleListTileState extends State<SimpleListTile> {
  var _isHovered = false;

  bool get _tracksHover => widget.hoverColor != null && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: widget.backgroundColor ?? Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 30),
          color: (_tracksHover && _isHovered)
              ? widget.hoverColor
              : Colors.transparent,
          padding: widget.padding,
          child: Row(
            children: [
              if (widget.leading != null) widget.leading!,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: (widget.leading != null) ? widget.leadingToTitle : 0,
                    right: _defaultGap,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widget.title,
                      if (widget.subtitle != null) widget.subtitle!,
                    ],
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );

    if (!_tracksHover) return tile;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: tile,
    );
  }
}
