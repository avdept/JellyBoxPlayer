import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';

class LibraryView extends ConsumerWidget {
  const LibraryView({
    required this.library,
    this.onTap,
    super.key,
  });

  final LibraryDTO library;
  final VoidCallback? onTap;

  String? imagePath(WidgetRef ref) {
    if (library.imageTags['Primary'] == null) return null;

    return ref.read(imageProvider).imagePath(tagId: library.imageTags['Primary']!, id: library.id);
  }

  ImageProvider libraryImage(WidgetRef ref) {
    if (imagePath(ref) != null) return NetworkImage(imagePath(ref)!);

    return const AssetImage(Images.librarySample);
  }

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
            library.name ?? 'Untitled',
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
