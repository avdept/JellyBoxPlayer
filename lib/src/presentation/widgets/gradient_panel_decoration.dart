import 'package:flutter/material.dart';

class GradientPanelDecoration extends StatelessWidget {
  const GradientPanelDecoration({
    this.child,
    super.key,
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final color = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      padding: EdgeInsets.only(
        left: padding.left,
        right: padding.right,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(1),
            color.withOpacity(0),
          ],
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
