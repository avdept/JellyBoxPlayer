import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _scrollController = ScrollController();

  late Size _screenSize;
  late bool _isMobile;
  late bool _isDesktop;

  void _onAlbumTap() {
    final location = GoRouterState.of(context).fullPath;
    context.go('$location${Routes.album}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.sizeOf(context);

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isDesktop = deviceType == DeviceScreenType.desktop;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(_isMobile ? 16 : 30),
                child: Flex(
                  direction: _isMobile ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: _isMobile
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Downloads',
                      style: TextStyle(
                        fontSize: _isMobile ? 24 : 36,
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
                child: CustomScrollbar(
                  controller: _scrollController,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: _isMobile ? 16 : 30,
                      top: _isDesktop ? 0 : 6,
                      right: _isMobile ? 16 : 30,
                      bottom: _isMobile ? 16 : 24,
                    ),
                    gridDelegate: _isDesktop
                        ? const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 245,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 30,
                            childAspectRatio: 245 / 297.3,
                          )
                        : SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: _isMobile ? 12 : 24,
                            mainAxisExtent: _isMobile ? 48 : 70,
                          ),
                    itemBuilder: (context, index) => DownloadedAlbumView(
                      name: 'Album name',
                      size: '124.6 MB',
                      onTap: _onAlbumTap,
                      onDeletePressed: () {},
                    ),
                    itemCount: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
