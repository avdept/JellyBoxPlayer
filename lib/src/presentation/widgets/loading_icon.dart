import 'package:flutter/material.dart';

class LoadingIcon extends StatelessWidget {
  const LoadingIcon({
    required this.icon,
    required this.spinner,
    this.overhang = 0.15,
    super.key,
  });

  final Widget icon;
  final Widget spinner;
  final double overhang;

  @override
  Widget build(BuildContext context) {
    final size = IconTheme.of(context).size ?? 24;
    final offset = -size * overhang;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Center(child: icon)),
          Positioned(right: offset, bottom: offset, child: spinner),
        ],
      ),
    );
  }
}
