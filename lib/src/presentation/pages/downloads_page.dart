import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  void _onAlbumTap(BuildContext context) {
    final location = GoRouterState.of(context).fullPath;
    context.go('$location${Routes.album}');
  }

  @override
  Widget build(BuildContext context) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));

    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(device.isMobile ? 60 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: device.isMobile ? 16 : 30),
          child: Row(
            children: [
              Text(
                'Downloads',
                style: TextStyle(
                  fontSize: device.isMobile ? 24 : 36,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              SizedBox(width: device.isMobile ? 12 : 24),
              Text(
                '12 albums',
                style: TextStyle(
                  fontSize: device.isMobile ? 12 : 16,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: device.isMobile ? 16 : 30,
        right: device.isMobile ? 16 : 30,
        bottom: device.isMobile ? 16 : 24,
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: device.isMobile ? 16 : 30,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: device.isDesktop
                ? const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 245,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 30,
                    childAspectRatio: 245 / 297.3,
                  )
                : SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: device.isMobile ? 12 : 24,
                    mainAxisExtent: device.isMobile ? 48 : 70,
                  ),
            itemBuilder: (context, index) => DownloadedAlbumView(
              name: 'Album name',
              size: '124.6 MB',
              onTap: () => _onAlbumTap(context),
              onDeletePressed: () {},
            ),
            itemCount: 20,
          ),
        ),
      ],
    );
  }
}
