import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({
    required this.name,
    this.onTap,
    super.key,
  });

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: Image(
              image: AssetImage(Images.librarySample),
              fit: BoxFit.fitWidth,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              height: 1.2,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
