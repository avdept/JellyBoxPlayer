import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';

class CoverMosaic extends StatelessWidget {
  const CoverMosaic({
    required this.images,
    this.borderRadius = 12,
    super.key,
  });

  final List<ImageProvider> images;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    if (images.length < 4) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          image: DecorationImage(
            image: images.isEmpty
                ? const AssetImage(Images.album)
                : images.first,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Column(
        children: [
          Expanded(child: _row(images[0], images[1])),
          Expanded(child: _row(images[2], images[3])),
        ],
      ),
    );
  }

  Widget _row(ImageProvider left, ImageProvider right) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: _tile(left)),
      Expanded(child: _tile(right)),
    ],
  );

  Widget _tile(ImageProvider image) => DecoratedBox(
    decoration: BoxDecoration(
      image: DecorationImage(image: image, fit: BoxFit.cover),
    ),
  );
}
