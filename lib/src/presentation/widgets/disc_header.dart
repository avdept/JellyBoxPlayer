import 'package:flutter/material.dart';

class DiscHeader extends StatelessWidget {
  const DiscHeader({
    required this.title,
    required this.fontSize,
    required this.edgePadding,
    this.leading,
    this.trailing,
    super.key,
  });

  final String title;
  final double fontSize;
  final double edgePadding;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onPrimary.withValues(alpha: 0.8);
    return Padding(
      padding: EdgeInsets.fromLTRB(edgePadding, 14, edgePadding, 2),
      child: Row(
        children: [
          if (leading case final leading?) ...[
            leading,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (trailing case final trailing?)
            IconTheme.merge(
              data: IconThemeData(color: color),
              child: trailing,
            ),
        ],
      ),
    );
  }
}
