import 'package:flutter/material.dart';

class CirclePlayButton extends StatefulWidget {
  const CirclePlayButton({
    required this.size,
    this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final double size;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<CirclePlayButton> createState() => _CirclePlayButtonState();
}

class _CirclePlayButtonState extends State<CirclePlayButton> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.15 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: SizedBox.square(
          dimension: size,
          child: MaterialButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            color: const Color(0xFF0066FF),
            disabledColor: const Color(0xFF0066FF),
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            elevation: _isHovered ? 8 : 4,
            child: widget.isLoading
                ? SizedBox.square(
                    dimension: size * 0.4,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.play_arrow_outlined,
                    size: size * 0.65,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
