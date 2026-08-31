import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/rail_collapse_animation.dart';
import 'package:jplayer/src/presentation/widgets/rail_tooltip.dart';

class CustomNavigationRail extends StatefulWidget {
  const CustomNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.width = 240,
    this.collapsedWidth = 76,
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
                  _itemView(index),
                const Spacer(),
                ?trailing,
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

  Widget _itemView(int index) {
    final destination = widget.destinations[index];
    final selected = index == widget.selectedIndex;
    final button = RailItemButton(
      onPressed: () => widget.onDestinationSelected?.call(index),
      icon: selected ? destination.selectedIcon : destination.icon,
      label: destination.label,
      foregroundColor: selected
          ? widget.selectedItemColor
          : widget.unselectedItemColor,
      backgroundColor: selected ? destination.indicatorColor : null,
      fontSize: selected ? widget.selectedFontSize : widget.unselectedFontSize,
      height: widget.itemHeight,
      horizontalPadding: widget.padding.left + _horizontalPadding(destination),
    );

    final label = destination.label;
    final message = label is Text ? label.data : null;

    return message != null
        ? RailTooltip(
            message: message,
            enabled: widget.collapsed,
            child: button,
          )
        : button;
  }
}

class RailItemButton extends StatelessWidget {
  const RailItemButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.foregroundColor,
    this.backgroundColor,
    this.fontSize,
    this.height = 48,
    this.horizontalPadding = 0,
    this.labelGap = 16,
    this.iconSize = 24,
    super.key,
  });

  final Widget icon;
  final Widget label;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double? fontSize;
  final double height;
  final double horizontalPadding;
  final double labelGap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final alignT = RailCollapseAnimation.progressOf(context, railAlignCurve);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        shape: const RoundedRectangleBorder(),
        splashFactory: NoSplash.splashFactory,
        padding: EdgeInsets.symmetric(
          horizontal: lerpDouble(0, horizontalPadding, alignT)!,
        ),
        iconSize: iconSize,
        minimumSize: const Size.fromHeight(40),
        fixedSize: Size.fromHeight(height),
        alignment: Alignment.lerp(
          Alignment.center,
          Alignment.centerLeft,
          alignT,
        ),
        textStyle: TextStyle(fontSize: fontSize),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          Flexible(
            child: CollapsibleLabel(
              child: Padding(
                padding: EdgeInsets.only(left: labelGap),
                child: label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
