import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/floating_panels.dart';

class PageNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const PageNavigationBar({
    required this.height,
    required this.horizontalPadding,
    required this.child,
    super.key,
  });

  final double height;
  final double horizontalPadding;
  final Widget child;

  @override
  Size get preferredSize => Size.fromHeight(height);

  double heightIn(BuildContext context) =>
      FloatingPanels.barHeightOf(context, height);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: FloatingPanels.barPaddingOf(context, horizontalPadding),
    ),
    child: child,
  );
}
