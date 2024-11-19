import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class ClickableWidget extends StatefulWidget {
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
  State<ClickableWidget> createState() => _ClickableWidgetState();
}

class _ClickableWidgetState extends State<ClickableWidget> {
  final _isActive = ValueNotifier<bool>(false);

  late DeviceType _device;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final child = ValueListenableBuilder(
      valueListenable: _isActive,
      builder: (context, isActive, child) => DefaultTextStyle(
        style: TextStyle(
          decoration: isActive ? TextDecoration.underline : TextDecoration.none,
          decorationColor: widget.textStyle?.color,
        ).merge(widget.textStyle),
        child: widget.child,
      ),
    );

    if (_device.isDesktop) {
      return MouseRegion(
        cursor: (widget.onPressed != null)
            ? WidgetStateMouseCursor.clickable
            : MouseCursor.defer,
        onHover: (_) => _isActive.value = true,
        onExit: (_) => _isActive.value = false,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: child,
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => _isActive.value = true,
        onTapUp: (_) => _isActive.value = false,
        onTapCancel: () => _isActive.value = false,
        child: child,
      );
    }
  }

  @override
  void dispose() {
    _isActive.dispose();
    super.dispose();
  }
}
