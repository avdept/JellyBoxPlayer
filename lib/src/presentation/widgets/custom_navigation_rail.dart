import 'package:flutter/material.dart';

class CustomNavigationRail extends StatelessWidget {
  const CustomNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.width = 240,
    this.elevation,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedFontSize = 14,
    this.unselectedFontSize = 12,
    this.leadingGap = 36,
    this.padding = EdgeInsets.zero,
    this.leading,
    this.trailing,
    super.key,
  });

  final List<NavigationRailDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final double width;
  final double? elevation;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double selectedFontSize;
  final double unselectedFontSize;
  final double leadingGap;
  final EdgeInsets padding;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Material(
        color: backgroundColor ?? theme.navigationRailTheme.backgroundColor,
        elevation: elevation ?? theme.navigationRailTheme.elevation ?? 0,
        child: SafeArea(
          left: false,
          right: false,
          minimum: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(height: leadingGap),
              ],
              ...List.generate(destinations.length, _itemView),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemView(int index) {
    final selected = index == selectedIndex;

    return TextButton.icon(
      onPressed: () => onDestinationSelected?.call(index),
      icon: selected
          ? destinations[index].selectedIcon
          : destinations[index].icon,
      label: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: destinations[index].label,
      ),
      style: TextButton.styleFrom(
        foregroundColor: selected ? selectedItemColor : unselectedItemColor,
        backgroundColor: selected ? destinations[index].indicatorColor : null,
        shape: destinations[index].indicatorShape as OutlinedBorder?,
        padding: destinations[index].padding,
        minimumSize: const Size.fromHeight(40),
        alignment: Alignment.centerLeft,
        textStyle: TextStyle(
          fontSize: selected ? selectedFontSize : unselectedFontSize,
        ),
      ),
    );
  }
}
