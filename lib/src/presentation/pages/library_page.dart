import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:responsive_builder/responsive_builder.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 30),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 30),
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
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isTablet ? 370 : 358,
                  mainAxisSpacing: isMobile ? 13 : 34,
                  crossAxisSpacing: isMobile ? 16 : (isTablet ? 34 : 24),
                  childAspectRatio: isTablet ? 370 / 255 : 358 / 233,
                ),
                itemBuilder: (context, index) => _libraryView(),
                itemCount: 10,
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
        ),
      );

  Widget _searchButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.search),
      );

  Widget _libraryView() => InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Ink.image(
                  image: const AssetImage(Images.librarySample),
                ),
              ),
            ),
            const Text(
              'Library name',
              style: TextStyle(
                fontSize: 16,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ],
        ),
      );
}
