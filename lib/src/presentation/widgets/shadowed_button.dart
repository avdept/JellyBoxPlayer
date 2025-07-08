import 'package:flutter/material.dart';

class ShadowedButton extends StatelessWidget {
  const ShadowedButton({
    required this.child,
    this.borderRadius,
    this.padding,
    this.color,
    this.shadowColor,
    this.onPressed,
    super.key,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? shadowColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(36);
    final color = this.color ?? const Color(0xFF404C6C);
    return InkWell(
      onTap: onPressed,
      borderRadius: borderRadius,
      child: Ink(
        padding:
            padding ?? const EdgeInsets.symmetric(vertical: 18, horizontal: 74),
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              offset: const Offset(-1, 3),
              color: shadowColor ?? color.withOpacity(0.7),
              spreadRadius: 4,
              blurRadius: 10,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
