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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 12 : 30,
                horizontal: isMobile ? 16 : 30,
              ),
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
            Expanded(
              child: Material(
                type: MaterialType.transparency,
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 30),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isTablet ? 370 : 358,
                    mainAxisSpacing: isMobile ? 13 : 34,
                    crossAxisSpacing: isMobile ? 16 : (isTablet ? 34 : 24),
                    childAspectRatio: isTablet ? 370 / 255 : 358 / 233,
                  ),
                  itemBuilder: (context, index) => LibraryView(
                    name: 'Library name',
                    onTap: () => _onLibraryTap(context),
                  ),
                  itemCount: 20,
                ),
              ),
            ),
          ],
        ),
      ),
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
