import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
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
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;
    final listItemExtent = isMobile ? 42.0 : 70.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 16 : 30,
                top: isMobile ? 16 : 30,
                right: isMobile ? 16 : 30,
                bottom: isMobile ? 22 : 32,
              ),
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
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 30 : 0),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isDesktop ? 245 : screenSize.width,
                    mainAxisSpacing: isDesktop ? 24 : 0,
                    crossAxisSpacing: 30,
                    childAspectRatio: 245 / 298.2,
                    mainAxisExtent: !isDesktop
                        ? listItemExtent + (isMobile ? 12 : 24)
                        : null,
                  ),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _onAlbumTap(context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Offstage(
                          offstage: !isDesktop,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Ink.image(
                              image: const AssetImage(Images.albumSample),
                            ),
                          ),
                        ),
                        SimpleListTile(
                          padding: isDesktop
                              ? EdgeInsets.zero
                              : EdgeInsets.symmetric(
                                  vertical: isMobile ? 6 : 12,
                                  horizontal: isMobile ? 16 : 30,
                                ),
                          leading: Offstage(
                            offstage: isDesktop,
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
        icon: const Icon(JPlayer.trash_2),
      );
}
