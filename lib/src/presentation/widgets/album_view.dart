import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AlbumView extends StatelessWidget {
  const AlbumView({
    required this.name,
    this.onTap,
    super.key,
  });

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage(Images.albumSample),
                ),
              ),
            ),
          ),
          Text(
            name,
            style: TextStyle(
              fontSize: isTablet ? 24 : 16,
              fontWeight: FontWeight.w500,
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
