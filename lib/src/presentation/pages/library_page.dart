import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
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
                  const Text(
                    'Your library',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                itemBuilder: (context, index) => Column(
                  children: [
                    Expanded(
                      child: Container(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Some text',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                itemCount: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.search),
      );
}
