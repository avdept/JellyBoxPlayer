import 'package:flutter/material.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.label,
    required this.fontSize,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String label;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(
      label,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
    ),
  );
}
