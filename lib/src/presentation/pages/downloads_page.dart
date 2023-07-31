import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.all(isMobile ? 16 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 22 : 32),
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
            if (isDesktop)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 245,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 30,
                    childAspectRatio: 245 / 298.2,
                  ),
                  itemBuilder: (context, index) => Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AspectRatio(
                        aspectRatio: 1,
                        child: ColoredBox(color: Colors.red),
                      ),
                      DefaultTextStyle(
                        style: const TextStyle(height: 1.2),
                        child: SimpleListTile(
                          title: Text(
                            'Album name',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onPrimary,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          subtitle: Text(
                            '124.6 MB',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  theme.colorScheme.onPrimary.withOpacity(0.61),
                            ),
                          ),
                          trailing: _deleteButton(),
                        ),
                      ),
                    ],
                  ),
                  itemCount: 10,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) => SimpleListTile(
                    leading: SizedBox.square(
                      dimension: isMobile ? 42 : 70,
                      child: const ColoredBox(color: Colors.red),
                    ),
                    title: Text(
                      'Album name',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      '124.6 MB',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onPrimary.withOpacity(0.61),
                      ),
                    ),
                    trailing: _deleteButton(),
                    leadingToTitle: isMobile ? 6 : 16,
                  ),
                  separatorBuilder: (context, index) => SizedBox(
                    height: isMobile ? 12 : 24,
                  ),
                  itemCount: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _deleteButton() => IconButton(
        onPressed: () {},
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.delete_outline),
      );
}
