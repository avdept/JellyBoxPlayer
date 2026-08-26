import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/rail_collapse_animation.dart';

class CustomNavigationRail extends StatefulWidget {
  const CustomNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.width = 240,
    this.collapsedWidth = 60,
    this.collapsed = false,
    this.elevation,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedFontSize = 14,
    this.unselectedFontSize = 12,
    this.leadingGap = 36,
    this.leadingHeight = 40,
    this.itemHeight = 48,
    this.padding = EdgeInsets.zero,
    this.leading,
    this.trailing,
    super.key,
  });

  final List<NavigationRailDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final double width;
  final double collapsedWidth;
  final bool collapsed;
  final double? elevation;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double selectedFontSize;
  final double unselectedFontSize;
  final double leadingGap;
  final double leadingHeight;
  final double itemHeight;
  final EdgeInsets padding;
  final Widget? leading;
  final Widget? trailing;

  @override
  State<CustomNavigationRail> createState() => _CustomNavigationRailState();
}

class _CustomNavigationRailState extends State<CustomNavigationRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: railCollapseDuration,
    value: widget.collapsed ? 0 : 1,
  );

  @override
  void didUpdateWidget(CustomNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collapsed != oldWidget.collapsed) {
      if (widget.collapsed) {
        unawaited(_controller.reverse());
      } else {
        unawaited(_controller.forward());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RailCollapseAnimation(
      animation: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _railView(context),
      ),
    );
  }

  Widget _railView(BuildContext context) {
    final theme = NavigationRailTheme.of(context);
    final progress = _controller.value.clamp(0.0, 1.0);
    final t = railWidthCurve.transform(progress);
    final alignT = railAlignCurve.transform(progress);
    final destinations = widget.destinations;
    final leading = widget.leading;
    final trailing = widget.trailing;

    final sideInset = lerpDouble(0, widget.padding.left, t)!;

    return ClipRect(
      child: SizedBox(
        width: lerpDouble(widget.collapsedWidth, widget.width, t),
        child: Material(
          color: widget.backgroundColor ?? theme.backgroundColor,
          elevation: widget.elevation ?? theme.elevation ?? 0,
          child: SafeArea(
            left: false,
            right: false,
            minimum: widget.padding.copyWith(left: 0, right: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leading != null) ...[
                  SizedBox(
                    height: widget.leadingHeight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: sideInset,
                        right: lerpDouble(
                          (widget.collapsedWidth - widget.leadingHeight) / 2,
                          widget.padding.right,
                          t,
                        )!,
                      ),
                      child: leading,
                    ),
                  ),
                  SizedBox(height: widget.leadingGap),
                ],
                for (var index = 0; index < destinations.length; index++)
                  _itemView(index, alignT),
                const Spacer(),
                if (trailing != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideInset),
                    child: Align(
                      alignment: _rowAlignment(alignT),
                      child: trailing,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _horizontalPadding(NavigationRailDestination destination) {
    final padding = destination.padding?.resolve(Directionality.of(context));
    return (padding?.horizontal ?? 0) / 2;
  }

  Alignment _rowAlignment(double t) =>
      Alignment.lerp(Alignment.center, Alignment.centerLeft, t)!;

  Widget _itemView(int index, double alignT) {
    final destination = widget.destinations[index];
    final selected = index == widget.selectedIndex;
    final button = TextButton(
      onPressed: () => widget.onDestinationSelected?.call(index),
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? widget.selectedItemColor
            : widget.unselectedItemColor,
        backgroundColor: selected ? destination.indicatorColor : null,
        shape: const RoundedRectangleBorder(),
        splashFactory: NoSplash.splashFactory,
        padding: EdgeInsets.symmetric(
          horizontal: lerpDouble(
            0,
            widget.padding.left + _horizontalPadding(destination),
            alignT,
          )!,
        ),
        minimumSize: const Size.fromHeight(40),
        fixedSize: Size.fromHeight(widget.itemHeight),
        alignment: _rowAlignment(alignT),
        textStyle: TextStyle(
          fontSize: selected
              ? widget.selectedFontSize
              : widget.unselectedFontSize,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) destination.selectedIcon else destination.icon,
          Flexible(
            child: CollapsibleLabel(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: destination.label,
              ),
            ),
          ),
        ],
      ),
    );

    final label = destination.label;

    return widget.collapsed && label is Text && label.data != null
        ? Tooltip(message: label.data, child: button)
        : button;
  }
}
