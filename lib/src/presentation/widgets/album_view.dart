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
    this.optionsBuilder,
    this.mainTextStyle,
    this.subTextStyle,
    this.showArtist = true,
    super.key,
  });

  final ItemDTO album;
  final bool showArtist;
  final void Function(ItemDTO)? onTap;
  final List<PopupMenuEntry<void>> Function(BuildContext)? optionsBuilder;
  final TextStyle? mainTextStyle;
  final TextStyle? subTextStyle;

  String? imagePath(WidgetRef ref) {
    if (album.imageTags['Primary'] == null) return null;

    return ref
        .read(imageProvider)
        .imagePath(tagId: album.imageTags['Primary']!, id: album.id);
  }

  ImageProvider libraryImage(WidgetRef ref) {
    if (imagePath(ref) != null) return NetworkImage(imagePath(ref)!);

    return const AssetImage(Images.album);
  }

  String get artistName {
    if (showArtist) {
      return album.albumArtist ?? '';
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isTablet = deviceType == DeviceScreenType.tablet;

    return GestureDetector(
      onTap: (onTap != null) ? () => onTap!.call(album) : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: libraryImage(ref),
                    ),
                  ),
                ),
                if (optionsBuilder != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<void>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'More',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                      itemBuilder: optionsBuilder!,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            album.name,
            style: TextStyle(
              fontSize: isTablet ? 24 : 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
              overflow: TextOverflow.ellipsis,
            ).merge(mainTextStyle),
            maxLines: 1,
          ),
          Text(
            artistName,
            style: TextStyle(
              fontSize: isTablet ? 22 : 14,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: const Color.fromARGB(130, 255, 255, 255),
              overflow: TextOverflow.ellipsis,
            ).merge(subTextStyle),
          ),
        ],
      ),
    );
  }
}
