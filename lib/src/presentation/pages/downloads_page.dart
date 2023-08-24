import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  void _onAlbumTap(BuildContext context) {
    final location = GoRouterState.of(context).fullPath;
    context.go('$location${Routes.album}');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 30),
                child: Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: isMobile
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Downloads',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 36,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Text(
                      '12 albums',
                      style: TextStyle(
                        fontSize: 16,
                        height: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.only(
                    left: isMobile ? 16 : 30,
                    top: isDesktop ? 0 : 6,
                    right: isMobile ? 16 : 30,
                    bottom: isMobile ? 16 : 24,
                  ),
                  gridDelegate: isDesktop
                      ? const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 245,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 30,
                          childAspectRatio: 245 / 293,
                        )
                      : SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: isMobile ? 12 : 24,
                          mainAxisExtent: isMobile ? 48 : 70,
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
          ),
        ),
      ),
    );
  }
}
