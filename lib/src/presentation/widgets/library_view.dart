import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class LibraryView extends ConsumerWidget {
  const LibraryView({
    required this.library,
    this.onTap,
    super.key,
  });

  final LibraryItem library;
  final VoidCallback? onTap;

  ImageProvider libraryImage(WidgetRef ref) => ref
      .read(imageServiceProvider)
      .itemImage(library, fallback: Images.librarySample);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image(
              image: libraryImage(ref),
              fit: BoxFit.fitWidth,
            ),
          ),
          Text(
            library.name,
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
