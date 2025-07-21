import 'package:flutter/cupertino.dart' show CupertinoDialogAction;
import 'package:flutter/material.dart';

class AdaptiveDialogAction extends StatelessWidget {
  const AdaptiveDialogAction({
    required this.child,
    this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDefaultAction;
  final bool isDestructiveAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (theme.platform) {
      TargetPlatform.iOS => CupertinoDialogAction(
        onPressed: onPressed,
        isDefaultAction: isDefaultAction,
        isDestructiveAction: isDestructiveAction,
        child: child,
      ),
      _ => TextButton(
        onPressed: onPressed,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontWeight: isDefaultAction ? FontWeight.w600 : null,
            color: isDestructiveAction ? theme.colorScheme.error : null,
          ),
          child: child,
        ),
      ),
    };
  }
}
