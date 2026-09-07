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

  bool get _isInteractive => widget.onPressed != null;

  void _setActive(bool value) {
    if (!_isInteractive && value) return;
    _isActive.value = value;
  }

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
        textWidthBasis: TextWidthBasis.longestLine,
        child: widget.child,
      ),
    );

    if (_device.isDesktop) {
      return MouseRegion(
        cursor: (widget.onPressed != null)
            ? WidgetStateMouseCursor.clickable
            : MouseCursor.defer,
        onHover: (_) => _setActive(true),
        onExit: (_) => _setActive(false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: child,
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => _setActive(true),
        onTapUp: (_) => _setActive(false),
        onTapCancel: () => _setActive(false),
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
