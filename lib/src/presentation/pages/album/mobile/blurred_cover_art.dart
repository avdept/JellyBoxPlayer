import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class BlurredCoverArt extends StatelessWidget {
  const BlurredCoverArt({
    required this.image,
    required this.width,
    required this.height,
    this.background,
    this.blurStart = 0.35,
    this.sigma = 40,
    super.key,
  });

  final ImageProvider image;
  final double width;
  final double height;
  final Color? background;
  final double blurStart;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final background =
        this.background ?? Theme.of(context).scaffoldBackgroundColor;
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(image: image, fit: BoxFit.cover),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Colors.transparent, Colors.black],
                  stops: [blurStart, 1],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: sigma,
                    sigmaY: sigma,
                    tileMode: TileMode.mirror,
                  ),
                  child: Image(image: image, fit: BoxFit.cover),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      background.withValues(alpha: 0),
                      background.withValues(alpha: 0.6),
                      background,
                    ],
                    stops: [blurStart, (blurStart + 1) / 2, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
