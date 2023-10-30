import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AlbumView extends ConsumerWidget {
  const AlbumView({
    required this.album,
    this.onTap,
    super.key,
  });

  final ItemDTO album;
  final VoidCallback? onTap;

  String? imagePath(WidgetRef ref) {
    if (album.imageTags['Primary'] == null) return null;

    return ref.read(imageProvider).imagePath(tagId: album.imageTags['Primary']!, id: album.id);
  }

  ImageProvider libraryImage(WidgetRef ref) {
    if (imagePath(ref) != null) return NetworkImage(imagePath(ref)!);

    return const AssetImage(Images.albumSample);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isTablet = deviceType == DeviceScreenType.tablet;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: libraryImage(ref),
                ),
              ),
            ),
          ),
          Text(
            album.name,
            style: TextStyle(
              fontSize: isTablet ? 24 : 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          Text(
            album.albumArtist ?? '',
            style: TextStyle(
              fontSize: isTablet ? 22 : 14,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: const Color.fromARGB(130, 255, 255, 255),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
