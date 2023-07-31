import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ListenPage extends StatelessWidget {
  const ListenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 30),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 30),
              child: Row(
                children: [
                  ChipTheme(
                    data: ChipTheme.of(context).copyWith(
                      labelStyle: TextStyle(fontSize: isMobile ? 14 : 24),
                    ),
                    child: Wrap(
                      spacing: isMobile ? 12 : 25,
                      children: const [
                        Chip(label: Text('Albums')),
                        Chip(label: Text('Artists')),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _settingsButton(),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isTablet ? 360 : 175,
                  mainAxisSpacing: isMobile ? 15 : 24,
                  crossAxisSpacing: isMobile ? 8 : (isTablet ? 56 : 24),
                  childAspectRatio: isTablet ? 360 / 413 : 175 / 206,
                ),
                itemBuilder: (context, index) => Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Text(
                      'Album name',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 16,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _settingsButton() => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.equalizer),
      );
}
