import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
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
    final listItemExtent = isMobile ? 42.0 : 70.0;

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
              child: Material(
                type: MaterialType.transparency,
                clipBehavior: Clip.hardEdge,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isDesktop ? 245 : screenSize.width,
                    mainAxisSpacing: isMobile ? 12 : 24,
                    crossAxisSpacing: 30,
                    childAspectRatio: 245 / 298.2,
                    mainAxisExtent: isDesktop ? null : listItemExtent,
                  ),
                  itemBuilder: (context, index) => InkWell(
                    onTap: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Visibility(
                          visible: isDesktop,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Ink.image(
                              image: const AssetImage(Images.albumSample),
                            ),
                          ),
                        ),
                        SimpleListTile(
                          leading: Visibility(
                            visible: !isDesktop,
                            child: Ink.image(
                              image: const AssetImage(Images.albumSample),
                              width: listItemExtent,
                              height: listItemExtent,
                            ),
                          ),
                          title: Text(
                            'Album name',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.2,
                              color: theme.colorScheme.onPrimary,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          subtitle: Text(
                            '124.6 MB',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.2,
                              color:
                                  theme.colorScheme.onPrimary.withOpacity(0.61),
                            ),
                          ),
                          trailing: _deleteButton(),
                          leadingToTitle: isDesktop ? 0 : (isMobile ? 6 : 16),
                        ),
                      ],
                    ),
                  ),
                  itemCount: 10,
                ),
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
