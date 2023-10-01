import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  void _onLibraryTap(BuildContext context) => context.go(Routes.listen);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return ScrollablePageScaffold(
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 48 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 30),
          child: Row(
            children: [
              CircleAvatar(
                radius: isDesktop ? 22.5 : 13,
              ),
              const SizedBox(width: 10),
              _titleText(),
              const Spacer(),
              _searchButton(),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: isMobile ? 16 : 30,
        right: isMobile ? 16 : 30,
        bottom: isMobile ? 8 : 20,
      ),
      slivers: [
        SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isTablet ? 370 : 358,
            mainAxisSpacing: isMobile ? 13 : 34,
            crossAxisSpacing: isDesktop ? 24 : (isMobile ? 16 : 34),
            childAspectRatio: 370 / 255,
          ),
          itemBuilder: (context, index) => LibraryView(
            name: 'Library name',
            onTap: () => _onLibraryTap(context),
          ),
          itemCount: 20,
        ),
      ],
    );
  }

  Widget _titleText() => const Text(
        'Your library',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );

  Widget _searchButton() => IconButton(
        onPressed: () {},
        icon: const Icon(JPlayer.search),
      );
}
