import 'package:flutter/material.dart';

const _defaultGap = 8.0;

class SimpleListTile extends StatelessWidget {
  const SimpleListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.leadingToTitle = _defaultGap,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final double leadingToTitle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) leading!,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: (leading != null) ? leadingToTitle : 0,
                right: _defaultGap,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  if (subtitle != null) subtitle!,
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
