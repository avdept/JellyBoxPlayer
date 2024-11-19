import 'package:flutter/material.dart';

class ClickableWidget extends StatelessWidget {
  const ClickableWidget({
    required this.child,
    this.textStyle,
    this.onPressed,
    super.key,
  });

  final Widget child;
  final TextStyle? textStyle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: true,
      child: StatefulBuilder(
        builder: (context, setState) {
          final focusNode = Focus.of(context);
          return DefaultTextStyle(
            style: TextStyle(
              decoration: focusNode.hasFocus
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: textStyle?.color,
            ).merge(textStyle),
            child: GestureDetector(
              onTap: onPressed,
              onTapDown: (_) {
                if (focusNode.canRequestFocus) setState(focusNode.requestFocus);
              },
              onTapUp: (_) => setState(focusNode.unfocus),
              onTapCancel: () => setState(focusNode.unfocus),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
